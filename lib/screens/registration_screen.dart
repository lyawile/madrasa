import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/madrasa_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _guardianNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Dynamic list of pupils being added
  final List<Map<String, TextEditingController>> _pupilControllers = [];

  @override
  void initState() {
    super.initState();
    // Start with one pupil form by default
    _addPupilInput();
  }

  @override
  void dispose() {
    _guardianNameController.dispose();
    _phoneController.dispose();
    for (final controllers in _pupilControllers) {
      controllers['name']?.dispose();
      controllers['class']?.dispose();
    }
    super.dispose();
  }

  void _addPupilInput() {
    setState(() {
      _pupilControllers.add({
        'name': TextEditingController(),
        'class': TextEditingController(text: 'Class 1'), // Default level
      });
    });
  }

  void _removePupilInput(int index) {
    if (_pupilControllers.length > 1) {
      setState(() {
        final removed = _pupilControllers.removeAt(index);
        removed['name']?.dispose();
        removed['class']?.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one pupil must be added to register.'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<MadrasaProvider>(context, listen: false);
      
      final List<Map<String, String>> pupils = [];
      for (final controllers in _pupilControllers) {
        final name = controllers['name']!.text.trim();
        final level = controllers['class']!.text.trim();
        if (name.isNotEmpty) {
          pupils.add({'name': name, 'class': level});
        }
      }

      if (pupils.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please provide a name for at least one pupil.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      try {
        await provider.registerParentWithStudents(
          guardianName: _guardianNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          pupilDetails: pupils,
        );

        // Success Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Household successfully registered!'),
            backgroundColor: Colors.teal,
          ),
        );

        // Reset inputs
        _guardianNameController.clear();
        _phoneController.clear();
        for (final controllers in _pupilControllers) {
          controllers['name']?.dispose();
          controllers['class']?.dispose();
        }
        _pupilControllers.clear();
        _addPupilInput();
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Elegant Header
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF064E3B), // Deep Emerald Green
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Registration Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          
          // Form Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section A: Parent details card
                    _buildCard(
                      title: 'Section A: Parent / Guardian Details',
                      icon: Icons.person_outline,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _guardianNameController,
                            decoration: const InputDecoration(
                              labelText: 'Parent / Guardian Full Name',
                              prefixIcon: Icon(Icons.person, color: Color(0xFF0F766E)),
                              border: OutlineInputBorder(),
                              hintText: 'e.g. Salim Omar',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter parent/guardian name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Primary Phone Number (Optional)',
                              prefixIcon: Icon(Icons.phone, color: Color(0xFF0F766E)),
                              border: OutlineInputBorder(),
                              hintText: 'e.g. +254 712 345678',
                            ),
                            // Phone is optional: passes validation if empty
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Section B: Pupils details list
                    _buildCard(
                      title: 'Section B: Pupil Details',
                      icon: Icons.child_care,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pupilControllers.length,
                            separatorBuilder: (_, __) => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Divider(thickness: 1),
                            ),
                            itemBuilder: (context, index) {
                              final pupilMap = _pupilControllers[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFE6F4EA),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF064E3B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: pupilMap['name'],
                                          decoration: const InputDecoration(
                                            labelText: 'Pupil Full Name',
                                            border: OutlineInputBorder(),
                                            hintText: 'e.g. Fatima Salim',
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please enter pupil\'s full name';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12.0),
                                        DropdownButtonFormField<String>(
                                          value: pupilMap['class']!.text,
                                          decoration: const InputDecoration(
                                            labelText: 'Class / Level',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: const [
                                            DropdownMenuItem(value: 'Class 1', child: Text('Class 1 (Beginners)')),
                                            DropdownMenuItem(value: 'Class 2', child: Text('Class 2 (Intermediate)')),
                                            DropdownMenuItem(value: 'Class 3', child: Text('Class 3 (Advanced)')),
                                            DropdownMenuItem(value: 'Class 4', child: Text('Class 4 (Memorization)')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                pupilMap['class']!.text = val;
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_pupilControllers.length > 1) ...[
                                    const SizedBox(width: 8.0),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () => _removePupilInput(index),
                                      tooltip: 'Remove Sibling',
                                    )
                                  ]
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16.0),
                          OutlinedButton.icon(
                            onPressed: _addPupilInput,
                            icon: const Icon(Icons.add, color: Color(0xFF064E3B)),
                            label: const Text(
                              'Add Another Pupil (Sibling)',
                              style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF064E3B), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF064E3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Register Household',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                    
                    const SizedBox(height: 32.0),
                    
                    // Registered Households Section
                    const Row(
                      children: [
                        Icon(Icons.people, color: Color(0xFF064E3B)),
                        SizedBox(width: 8.0),
                        Text(
                          'Registered Households',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF064E3B),
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1.5),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ),
          
          // List of Registered Households
          Consumer<MadrasaProvider>(
            builder: (context, provider, child) {
              if (provider.parents.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.people_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 12.0),
                          Text(
                            'No parents registered yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 16.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              return SliverPadding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 32.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final parent = provider.parents[index];
                      final children = provider.parentToStudents[parent.id] ?? [];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: ExpansionTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF0F766E),
                            child: Icon(Icons.family_restroom, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            parent.guardianName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                          ),
                          subtitle: parent.phoneNumber != null && parent.phoneNumber!.isNotEmpty
                              ? Text(
                                  parent.phoneNumber!,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 14.0),
                                )
                              : Text(
                                  'No phone number added',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14.0,
                                  ),
                                ),
                          children: [
                            Container(
                              color: Colors.grey[50],
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Registered Pupils (${children.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.0,
                                      color: Color(0xFF0F766E),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0),
                                  if (children.isEmpty)
                                    const Text('No pupils registered for this household.')
                                  else
                                    ...children.map((child) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF0F766E)),
                                          const SizedBox(width: 4.0),
                                          Expanded(
                                            child: Text(
                                              child.fullName,
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0),
                                            ),
                                          ),
                                          Chip(
                                            label: Text(
                                              child.classId,
                                              style: const TextStyle(fontSize: 11.0, color: Color(0xFF064E3B), fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: const Color(0xFFE6F4EA),
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          )
                                        ],
                                      ),
                                    )).toList(),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                    childCount: provider.parents.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF064E3B)),
                const SizedBox(width: 8.0),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF064E3B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            const Divider(thickness: 1),
            const SizedBox(height: 8.0),
            child,
          ],
        ),
      ),
    );
  }
}
