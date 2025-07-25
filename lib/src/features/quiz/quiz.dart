/// Barrel file for the complete quiz feature
/// 
/// This exports all public APIs for the quiz module following Clean Architecture.
/// External modules should only import from this file to access quiz functionality.
library;

// Domain Layer - Core business entities and logic
export 'domain/domain.dart';

// Application Layer - Use cases and application services  
export 'application/application.dart';

// Presentation Layer - UI components and screens
export 'presentation/presentation.dart';

// Note: Data layer is not exported as it's an implementation detail
// External modules should only depend on domain and application layers
