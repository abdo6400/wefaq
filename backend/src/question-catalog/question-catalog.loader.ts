import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { Injectable } from '@nestjs/common';

export const DEFAULT_CATALOG_FILENAME = 'question-catalog.v1.json';

@Injectable()
export class QuestionCatalogLoader {
  /**
   * Resolves and parses the configured JSON catalog snapshot file.
   * Supports CATALOG_FILE_PATH overrides for custom deployments and tests.
   */
  loadRawSnapshot(explicitPath?: string): unknown {
    const resolvedPath = this.resolveCatalogPath(explicitPath);
    const content = readFileSync(resolvedPath, 'utf8');
    return JSON.parse(content) as unknown;
  }

  resolveCatalogPath(explicitPath?: string): string {
    const configured = explicitPath ?? process.env.CATALOG_FILE_PATH;
    if (configured && configured.trim().length > 0) {
      const target = resolve(configured.trim());
      if (!existsSync(target)) {
        throw new Error(`Configured catalog file does not exist: ${target}`);
      }
      return target;
    }

    const candidates = [
      join(process.cwd(), 'data', DEFAULT_CATALOG_FILENAME),
      resolve(__dirname, '..', '..', 'data', DEFAULT_CATALOG_FILENAME),
      resolve(__dirname, '..', '..', '..', 'data', DEFAULT_CATALOG_FILENAME),
    ];

    for (const candidate of candidates) {
      if (existsSync(candidate)) {
        return candidate;
      }
    }

    throw new Error(
      `Question catalog snapshot "${DEFAULT_CATALOG_FILENAME}" could not be found in expected data directories.`,
    );
  }
}
