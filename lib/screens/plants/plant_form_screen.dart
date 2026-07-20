import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/plant.dart';
import '../../state/plants_store.dart';

class PlantFormScreen extends StatefulWidget {
  final Plant? plantToEdit;

  const PlantFormScreen({
    super.key,
    this.plantToEdit,
  });

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final List<String> _plantOptions = ['tomato', 'potato'];

  late String _selectedPlant;

  bool get _isEdit => widget.plantToEdit != null;

  @override
  void initState() {
    super.initState();
    _selectedPlant = widget.plantToEdit?.plantType ?? 'tomato';
  }

  String _plantImage(String plant) {
    switch (plant) {
      case 'tomato':
        return 'assets/images/Tomato.jpeg';
      case 'potato':
        return 'assets/images/Potato.jpeg';
      default:
        return 'assets/images/Tomato.jpeg';
    }
  }

  Future<void> _save() async {
    final store = context.read<PlantsStore>();

    String? error;

    if (_isEdit) {
      error = await store.updatePlant(
        plantId: widget.plantToEdit!.id,
        plantType: _selectedPlant,
      );
    } else {
      error = await store.addPlant(
        plantType: _selectedPlant,
      );
    }

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7F3),
        elevation: 0,
        centerTitle: true,
        title: Text(_isEdit ? 'Edit Plant' : 'Add Plant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _plantOptions.map((plant) {
                final selected = _selectedPlant == plant;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlant = plant;
                    });
                  },
                  child: Container(
                    width: 145,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected ? Colors.green : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          _plantImage(plant),
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Plant.displayName(plant),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(_isEdit ? 'Save Changes' : 'Add Plant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}