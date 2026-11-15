import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Operator Administrative CLI for Wefaq License Issuance and Slot Management.
///
/// Implements ADR 0002 & ADR 0005:
/// - Cryptographic code generation with 2-device slot caps.
/// - Slot replacement runbook for authorized customer service personnel.
/// - Immutable audit logging.
void main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printUsage();
    return;
  }

  final command = args[0].toLowerCase();
  final dbFile = File('data/admin_licenses.json');
  final auditFile = File('data/admin_audit.log');

  await _ensureStorage(dbFile);

  switch (command) {
    case 'issue':
      await _issueCode(args.sublist(1), dbFile, auditFile);
      break;
    case 'inspect':
      await _inspectCode(args.sublist(1), dbFile);
      break;
    case 'replace-slot':
      await _replaceSlot(args.sublist(1), dbFile, auditFile);
      break;
    case 'revoke':
      await _revokeCode(args.sublist(1), dbFile, auditFile);
      break;
    case 'audit':
      await _printAuditLog(auditFile);
      break;
    default:
      stdout.writeln('Unknown command: $command');
      _printUsage();
  }
}

Future<void> _ensureStorage(File dbFile) async {
  if (!await dbFile.exists()) {
    await dbFile.parent.create(recursive: true);
    await dbFile.writeAsString('{}');
  }
}

Future<void> _recordAudit(File auditFile, String action, String details) async {
  if (!await auditFile.parent.exists()) {
    await auditFile.parent.create(recursive: true);
  }
  final timestamp = DateTime.now().toUtc().toIso8601String();
  final entry = '[$timestamp] ACTION: $action | DETAILS: $details\n';
  await auditFile.writeAsString(entry, mode: FileMode.append, flush: true);
}

Future<void> _issueCode(List<String> args, File dbFile, File auditFile) async {
  var plan = 'couple-20';
  var quota = 20;
  var days = 180;
  var slots = 2;

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--plan' && i + 1 < args.length) {
      plan = args[++i];
    }
    if (args[i] == '--quota' && i + 1 < args.length) {
      quota = int.tryParse(args[++i]) ?? quota;
    }
    if (args[i] == '--days' && i + 1 < args.length) {
      days = int.tryParse(args[++i]) ?? days;
    }
    if (args[i] == '--slots' && i + 1 < args.length) {
      slots = int.tryParse(args[++i]) ?? slots;
    }
  }

  final rng = Random.secure();
  final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final part1 = List.generate(
    4,
    (_) => chars[rng.nextInt(chars.length)],
  ).join();
  final part2 = List.generate(
    4,
    (_) => chars[rng.nextInt(chars.length)],
  ).join();
  final code = 'WFQ-$part1-$part2';

  final raw = await dbFile.readAsString();
  final data = jsonDecode(raw) as Map<String, dynamic>;

  final record = {
    'code': code,
    'plan': plan,
    'totalQuota': quota,
    'remainingQuota': quota,
    'authorizedSlots': slots,
    'slot1': null,
    'slot2': null,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'expiresAt': DateTime.now()
        .toUtc()
        .add(Duration(days: days))
        .toIso8601String(),
    'isRevoked': false,
  };

  data[code] = record;
  await dbFile.writeAsString(jsonEncode(data), flush: true);
  await _recordAudit(
    auditFile,
    'ISSUE_CODE',
    'code=$code, plan=$plan, quota=$quota, slots=$slots',
  );

  stdout.writeln('Successfully issued license:');
  stdout.writeln('  Code:            $code');
  stdout.writeln('  Plan:            $plan');
  stdout.writeln('  Authorized Slots: $slots');
  stdout.writeln('  Total Quota:     $quota sessions');
  stdout.writeln('  Validity:        $days days');
}

Future<void> _inspectCode(List<String> args, File dbFile) async {
  if (args.isEmpty) {
    stdout.writeln('Error: Missing --code <CODE>');
    return;
  }
  final code = args.last.toUpperCase();
  final raw = await dbFile.readAsString();
  final data = jsonDecode(raw) as Map<String, dynamic>;

  final record = data[code];
  if (record == null) {
    stdout.writeln('License not found: $code');
    return;
  }

  stdout.writeln('License Details for $code:');
  stdout.writeln('  Plan:            ${record['plan']}');
  stdout.writeln(
    '  Remaining Quota: ${record['remainingQuota']} / ${record['totalQuota']}',
  );
  stdout.writeln('  Authorized Slots: ${record['authorizedSlots']}');
  stdout.writeln('  Slot 1 Binding:  ${record['slot1'] ?? 'UNOCCUPIED'}');
  stdout.writeln('  Slot 2 Binding:  ${record['slot2'] ?? 'UNOCCUPIED'}');
  stdout.writeln('  Expires At:      ${record['expiresAt']}');
  stdout.writeln('  Is Revoked:      ${record['isRevoked']}');
}

Future<void> _replaceSlot(
  List<String> args,
  File dbFile,
  File auditFile,
) async {
  String? code;
  int? slotNumber;
  String? newDeviceId;
  String? reason;

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--code' && i + 1 < args.length) {
      code = args[++i].toUpperCase();
    }
    if (args[i] == '--slot' && i + 1 < args.length) {
      slotNumber = int.tryParse(args[++i]);
    }
    if (args[i] == '--new-device' && i + 1 < args.length) {
      newDeviceId = args[++i];
    }
    if (args[i] == '--reason' && i + 1 < args.length) {
      reason = args[++i];
    }
  }

  if (code == null || slotNumber == null || newDeviceId == null) {
    stdout.writeln(
      'Error: Usage: replace-slot --code <code> --slot <1|2> --new-device <id> [--reason <text>]',
    );
    return;
  }

  final raw = await dbFile.readAsString();
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final record = data[code];

  if (record == null) {
    stdout.writeln('Error: License $code not found.');
    return;
  }

  final slotKey = slotNumber == 1 ? 'slot1' : 'slot2';
  final oldDevice = record[slotKey];
  record[slotKey] = newDeviceId;

  await dbFile.writeAsString(jsonEncode(data), flush: true);
  await _recordAudit(
    auditFile,
    'REPLACE_SLOT',
    'code=$code, slot=$slotNumber, oldDevice=$oldDevice, newDevice=$newDeviceId, reason=${reason ?? "Customer Device Change"}',
  );

  stdout.writeln('Successfully replaced slot $slotNumber on code $code:');
  stdout.writeln('  Previous device: $oldDevice');
  stdout.writeln('  New device:      $newDeviceId');
}

Future<void> _revokeCode(List<String> args, File dbFile, File auditFile) async {
  if (args.isEmpty) {
    stdout.writeln('Error: Missing --code <CODE>');
    return;
  }
  final code = args.last.toUpperCase();
  final raw = await dbFile.readAsString();
  final data = jsonDecode(raw) as Map<String, dynamic>;

  final record = data[code];
  if (record == null) {
    stdout.writeln('Error: License $code not found.');
    return;
  }

  record['isRevoked'] = true;
  await dbFile.writeAsString(jsonEncode(data), flush: true);
  await _recordAudit(auditFile, 'REVOKE_CODE', 'code=$code');

  stdout.writeln('Successfully revoked license: $code');
}

Future<void> _printAuditLog(File auditFile) async {
  if (!await auditFile.exists()) {
    stdout.writeln('No audit log entries recorded.');
    return;
  }
  final content = await auditFile.readAsString();
  stdout.writeln('--- Audit Log ---');
  stdout.write(content);
}

void _printUsage() {
  stdout.writeln('Wefaq License Manager (Operator CLI)');
  stdout.writeln('Commands:');
  stdout.writeln(
    '  issue [--plan <name>] [--quota <num>] [--days <days>] [--slots <2>]',
  );
  stdout.writeln('  inspect --code <CODE>');
  stdout.writeln(
    '  replace-slot --code <CODE> --slot <1|2> --new-device <ID> [--reason <text>]',
  );
  stdout.writeln('  revoke --code <CODE>');
  stdout.writeln('  audit');
}
