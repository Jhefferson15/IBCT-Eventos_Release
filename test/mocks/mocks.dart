import 'package:mocktail/mocktail.dart';
import 'package:ibct_eventos/features/auth/domain/repositories/auth_repository_interface.dart';
import 'package:ibct_eventos/features/survey/domain/repositories/survey_repository_interface.dart';
import 'package:ibct_eventos/features/survey/domain/usecases/submit_survey_usecase.dart';

class MockAuthRepository extends Mock implements IAuthRepository {}
class MockSurveyRepository extends Mock implements ISurveyRepository {}
class MockSubmitSurveyUseCase extends Mock implements SubmitSurveyUseCase {}
