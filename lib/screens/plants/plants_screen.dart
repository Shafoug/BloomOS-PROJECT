import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../state/plants_store.dart';
import 'plant_dashboard_screen.dart';
import 'plant_form_screen.dart';

class PlantsManagementScreen extends StatefulWidget {
  final bool isGuest;

  const PlantsManagementScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  State<PlantsManagementScreen> createState() => _PlantsManagementScreenState();
}

class _PlantsManagementScreenState extends State<PlantsManagementScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantsStore>().listenToPlants();
    });
  }

  String getImage(String type) {
    switch (type.toLowerCase()) {
      case 'tomato':
        return 'assets/images/Tomato.jpeg';
      case 'potato':
        return 'assets/images/Potato.jpeg';
      default:
        return 'assets/images/Tomato.jpeg';
    }
  }

  Future<void> _openAddPlant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlantFormScreen()),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openEditPlant(BuildContext context, Plant plant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantFormScreen(plantToEdit: plant)),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<bool> _confirmDelete(
      BuildContext context,
      PlantsStore store,
      Plant plant,
      ) async {
    final plantName = Plant.displayName(plant.plantType);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Plant'),
        content: Text('Are you sure you want to delete $plantName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await store.deletePlant(plant.id);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlantsStore>();
    final plants = store.plants;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F3),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Plants',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () => _openAddPlant(context),
          ),
        ],
      ),
      body: plants.isEmpty
          ? const Center(
        child: Text(
          'No plants yet 🌱',
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        itemCount: plants.length,
        itemBuilder: (context, index) {
          final plant = plants[index];

          return Dismissible(
            key: ValueKey(plant.id),
            background: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            secondaryBackground: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.delete, color: Colors.white),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await _openEditPlant(context, plant);
                return false;
              }

              if (direction == DismissDirection.endToStart) {
                return await _confirmDelete(context, store, plant);
              }

              return false;
            },
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlantDashboardScreen(
                      plant: plant,
                      isGuest: widget.isGuest,
                    ),
                  ),
                );
              },
              child: _buildPlantCard(plant),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlantCard(Plant plant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                getImage(plant.plantType),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const Icon(
                    Icons.local_florist_outlined,
                    size: 34,
                    color: Color(0xFF7AA874),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              Plant.displayName(plant.plantType),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF6F8E69),
            size: 28,
          ),
        ],
      ),
    );
  }
}