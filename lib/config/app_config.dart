class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cvcqnwoaxnagekvcqowk.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN2Y3Fud29heG5hZ2VrdmNxb3drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMDI0MDQsImV4cCI6MjA5MDc3ODQwNH0.b2lJdCrnX106coqSN2Fx0v6H4-39BvFDzdC3DxcWHBw',
  );

  static const String mistralApiUrl = String.fromEnvironment(
    'MISTRAL_API_URL',
    defaultValue: 'https://api.mistral.ai/v1/chat/completions',
  );

  static const String mistralApiKey = String.fromEnvironment(
    'MISTRAL_API_KEY',
    defaultValue: '',
  );

  static const String collegeWebsite = 'https://bridgewater.edu.np';
}
