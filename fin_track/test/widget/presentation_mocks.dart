import 'package:fin_track/domain/services/i_backup_service.dart';
import 'package:fin_track/domain/services/i_receipt_service.dart';
import 'package:fin_track/domain/services/i_configuration_service.dart';
import 'package:fin_track/domain/infrastructure/i_local_authentication_service.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<IReceiptService>(),
  MockSpec<IBackupService>(),
  MockSpec<IConfigurationService>(),
  MockSpec<ILocalAuthenticationService>(),
])
// ignore: unused_import
import 'presentation_mocks.mocks.dart';

export 'presentation_mocks.mocks.dart';
