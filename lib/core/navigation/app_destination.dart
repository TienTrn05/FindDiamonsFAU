enum AppDestination {
  dashboard('/dashboard', 'Home'),
  find('/find', 'Find'),
  history('/history', 'History'),
  skins('/skins', 'Skins'),
  servers('/servers', 'Servers'),
  maps('/maps', 'Maps');

  const AppDestination(this.route, this.label);
  final String route;
  final String label;
}
