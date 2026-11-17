import {
  Body,
  Controller,
  Get,
  Header,
  HttpCode,
  HttpStatus,
  Inject,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AdminTokenGuard } from '../common/guards/admin-token.guard';
import { LicensesService } from './licenses.service';

@Controller('v1/licenses')
@UseGuards(AdminTokenGuard)
export class LicensesController {
  constructor(
    @Inject(LicensesService)
    private readonly licensesService: LicensesService,
  ) {}

  @Get('config')
  @Header('Cache-Control', 'no-store')
  getConfig() {
    return this.licensesService.getSigningConfig();
  }

  @Post('keygen')
  @HttpCode(HttpStatus.OK)
  @Header('Cache-Control', 'no-store')
  keygen() {
    return this.licensesService.generateKeyPair();
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  async list(
    @Query('search') search?: string,
    @Query('status') status?: string,
  ) {
    return await this.licensesService.listLicenses(search, status);
  }

  @Post('generate')
  @HttpCode(HttpStatus.CREATED)
  @Header('Cache-Control', 'no-store')
  async generate(@Body() body: unknown) {
    return await this.licensesService.generateLicense(body);
  }

  @Patch(':id/revoke')
  @Header('Cache-Control', 'no-store')
  async revoke(@Param('id') id: string, @Body() body: unknown) {
    const record = await this.licensesService.revokeLicense(id, body);
    return { record };
  }
}
