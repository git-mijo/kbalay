class SplashState {
  SplashState({required this.isLoading});
  final bool isLoading;

  factory SplashState.init() => SplashState(isLoading: false);

  SplashState copyWith({bool? isLoading}){
    return SplashState(
      isLoading: isLoading ?? this.isLoading,
    );
  }
}