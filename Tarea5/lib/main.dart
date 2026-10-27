import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'data/models.dart';
import 'data/repository.dart';
import 'presentation/controller.dart';

void main() => runApp(const DirectoryApp());

class DirectoryApp extends StatelessWidget {
  const DirectoryApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Directorio UTESA',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF126E69)),
      scaffoldBackgroundColor: const Color(0xFFF3F7F6),
    ),
    home: const DirectoryScreen(),
  );
}

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});
  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  late final DirectoryController controller;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    controller = DirectoryController(
      DirectoryRepository(
        DirectoryApi(http.Client()),
        FavoritesStore(SharedPreferencesAsync()),
      ),
    );
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final list = tab == 0 ? controller.users : controller.favorites;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Directorio UTESA'),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: controller.loading ? null : controller.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'Usuarios',
            ),
            NavigationDestination(
              icon: Icon(Icons.star_outline),
              label: 'Favoritos',
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tab == 0 ? 'Conecta con las personas' : 'Siempre a mano',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tab == 0
                        ? 'Nombre, correo y empresa • JSONPlaceholder'
                        : '${list.length} favoritos guardados en este dispositivo',
                  ),
                ],
              ),
            ),
            if (controller.offline)
              const Notice('Sin Internet. Los favoritos siguen disponibles.'),
            if (controller.storageError != null)
              Notice(controller.storageError!),
            if (tab == 0 && controller.error != null) Notice(controller.error!),
            Expanded(
              child: tab == 0 && controller.loading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando usuarios…'),
                        ],
                      ),
                    )
                  : list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab == 0 ? Icons.cloud_off : Icons.star_outline,
                            size: 56,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tab == 0
                                ? 'No hay usuarios disponibles'
                                : 'Todavía no tienes favoritos',
                          ),
                          if (tab == 0)
                            TextButton(
                              onPressed: controller.load,
                              child: const Text('Reintentar'),
                            ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final user = list[i];
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(child: Text('${user.id}')),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${user.email}\n${user.company}'),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: controller.isFavorite(user)
                                  ? 'Quitar favorito'
                                  : 'Guardar favorito',
                              onPressed: controller.saving
                                  ? null
                                  : () => controller.toggle(user),
                              icon: Icon(
                                controller.isFavorite(user)
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFF947000),
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => DetailScreen(
                                  user: user,
                                  controller: controller,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class Notice extends StatelessWidget {
  final String text;
  const Notice(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9BF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text),
  );
}

class DetailScreen extends StatefulWidget {
  final User user;
  final DirectoryController controller;
  const DetailScreen({super.key, required this.user, required this.controller});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  List<Post> posts = [];
  bool loading = true;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (widget.controller.offline) {
        throw StateError('offline');
      }
      final result = await widget.controller.repository.api.posts(
        widget.user.id,
      );
      if (mounted) {
        setState(() => posts = result);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = widget.controller.offline
              ? 'Sin Internet. Los datos del favorito están guardados; sus publicaciones requieren conexión.'
              : 'No se pudieron cargar las publicaciones. Revisa Internet y reintenta.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final u = widget.user;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del usuario'),
          actions: [
            IconButton(
              tooltip: 'Cambiar favorito',
              onPressed: widget.controller.saving
                  ? null
                  : () => widget.controller.toggle(u),
              icon: Icon(
                widget.controller.isFavorite(u)
                    ? Icons.star
                    : Icons.star_border,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(u.name, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('@${u.username} • ID ${u.id}'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Correo: ${u.email}\nTeléfono: ${u.phone}\nWeb: ${u.website}\n'
                  'Empresa: ${u.company}\n${u.json['company']['catchPhrase']}\n'
                  'Actividad: ${u.json['company']['bs']}\nDirección: ${u.address}\n'
                  'Coordenadas: ${u.json['address']['geo']['lat']}, ${u.json['address']['geo']['lng']}',
                  style: const TextStyle(height: 1.6),
                ),
              ),
            ),
            if (widget.controller.storageError != null)
              Notice(widget.controller.storageError!),
            const SizedBox(height: 20),
            Text(
              'Publicaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (loading) const Center(child: CircularProgressIndicator()),
            if (error != null) ...[
              Notice(error!),
              TextButton(onPressed: load, child: const Text('Reintentar')),
            ],
            if (!loading && error == null && posts.isEmpty)
              const Text('Este usuario no tiene publicaciones.'),
            for (final p in posts)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(p.body),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
