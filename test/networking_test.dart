import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/config/dio_config.dart';
import 'package:delivery_app/utils/api_call_status.dart';
import 'package:delivery_app/utils/error_data.dart';
import 'package:delivery_app/utils/error_utils.dart';
import 'package:delivery_app/utils/templates/loaded_widgets_template.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SKILL.md Networking Architecture Tests', () {
    test('DioConfig singleton returns client with proper timeouts', () async {
      DioConfig.isTestMode = true;
      final client = await DioConfig.dio();
      expect(client.options.connectTimeout, const Duration(seconds: 60));
      expect(client.options.receiveTimeout, const Duration(seconds: 120));
      expect(client.options.headers['Accept'], 'application/json');
    });

    test('Dio error converter handles various error types', () {
      final cancelError = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.cancel,
      );
      expect(DioConfig.convertDioError(cancelError), 'Request cancelled');

      final timeoutError = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      );
      expect(DioConfig.convertDioError(timeoutError), 'Connection timeout');
    });

    test('ErrorUtil maps 401 and 404 to user-safe ErrorData', () async {
      final error401 = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 401,
        ),
      );
      final errorData401 = await ErrorUtil.getErrorData(error401);
      expect(errorData401.title, 'Unauthorized');
      expect(errorData401.buttonText, 'Log In');

      final error404 = DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 404,
        ),
      );
      final errorData404 = await ErrorUtil.getErrorData(error404);
      expect(errorData404.title, 'Not found');
    });

    testWidgets('LoadedWidget renders skeleton when status is loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadedWidget(
              status: ApiCallStatus.loading,
              loadingChild: Text('SKELETON_LOADING'),
              child: Text('CONTENT_SUCCESS'),
            ),
          ),
        ),
      );

      expect(find.text('SKELETON_LOADING'), findsOneWidget);
      expect(find.text('CONTENT_SUCCESS'), findsNothing);
    });

    testWidgets('LoadedWidget renders content when status is success', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadedWidget(
              status: ApiCallStatus.success,
              loadingChild: Text('SKELETON_LOADING'),
              child: Text('CONTENT_SUCCESS'),
            ),
          ),
        ),
      );

      expect(find.text('CONTENT_SUCCESS'), findsOneWidget);
      expect(find.text('SKELETON_LOADING'), findsNothing);
    });

    testWidgets('LoadedWidget renders error when status is error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadedWidget(
              status: ApiCallStatus.error,
              errorData: ErrorData(
                title: 'Network Error',
                body: 'Failed to fetch restaurants',
                buttonText: 'Retry',
              ),
              loadingChild: Text('SKELETON_LOADING'),
              child: Text('CONTENT_SUCCESS'),
            ),
          ),
        ),
      );

      expect(find.text('Network Error'), findsOneWidget);
      expect(find.text('Failed to fetch restaurants'), findsOneWidget);
      expect(find.text('CONTENT_SUCCESS'), findsNothing);
    });

    test('LoggingInterceptor processes onRequest, onResponse, and onError via Dio client', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.interceptors.add(LoggingInterceptor());

      final adapter = DioAdapter(dio: dio);
      adapter.onGet('/test-ok', (server) => server.reply(200, {'ok': true, 'data': 'Hello'}));
      adapter.onGet('/test-fail', (server) => server.reply(400, {'error': 'Bad Request'}));

      final res = await dio.get('/test-ok');
      expect(res.statusCode, 200);
      expect(res.data['ok'], true);

      try {
        await dio.get('/test-fail');
        fail('Should throw DioException on 400');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 400);
      }
    });

    test('LoggingInterceptor.parseBody parses FormData fields and MultipartFile metadata', () {
      // 1. Non-FormData inputs are returned unchanged
      expect(LoggingInterceptor.parseBody({'hello': 'world'}), {'hello': 'world'});
      expect(LoggingInterceptor.parseBody('raw string'), 'raw string');
      expect(LoggingInterceptor.parseBody(null), isNull);

      // 2. FormData with fields and files
      final formData = FormData.fromMap({
        'name': 'Bole Restaurant',
        'category_id': 5,
        'image': MultipartFile.fromString('dummy image content', filename: 'logo.jpg'),
      });

      final parsed = LoggingInterceptor.parseBody(formData);
      expect(parsed, isA<Map<String, dynamic>>());
      expect(parsed['name'], 'Bole Restaurant');
      expect(parsed['category_id'], '5');
      expect(parsed['image'], isA<Map<String, dynamic>>());
      expect(parsed['image']['filename'], 'logo.jpg');
      expect(parsed['image']['length'], 19);

      // 3. FormData with duplicate keys
      final multiFormData = FormData();
      multiFormData.fields.add(const MapEntry('tags', 'burger'));
      multiFormData.fields.add(const MapEntry('tags', 'fastfood'));
      multiFormData.files.add(MapEntry(
        'files',
        MultipartFile.fromString('file 1', filename: 'f1.txt'),
      ));
      multiFormData.files.add(MapEntry(
        'files',
        MultipartFile.fromString('file 2', filename: 'f2.txt'),
      ));

      final multiParsed = LoggingInterceptor.parseBody(multiFormData);
      expect(multiParsed['tags'], ['burger', 'fastfood']);
      expect(multiParsed['files'], isA<List>());
      expect((multiParsed['files'] as List).length, 2);
      expect(multiParsed['files'][0]['filename'], 'f1.txt');
      expect(multiParsed['files'][1]['filename'], 'f2.txt');
    });

    test('LoggingInterceptor intercepts and logs FormData request with DioAdapter', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.interceptors.add(LoggingInterceptor());

      final adapter = DioAdapter(dio: dio);
      adapter.onPost(
        '/upload',
        (server) => server.reply(200, {'success': true}),
        data: Matchers.any,
      );

      final formData = FormData.fromMap({
        'title': 'Test Item',
        'file': MultipartFile.fromString('test data', filename: 'test.png'),
      });

      final res = await dio.post('/upload', data: formData);
      expect(res.statusCode, 200);
      expect(res.data['success'], true);
    });
  });
}
