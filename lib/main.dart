import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MaterialApp(
    title: 'Home page',
    darkTheme: ThemeData.dark(),
    themeMode: ThemeMode.dark,
    home: const HomePage(),
  ));
}

class Person {
  final String name;
  final int age;
  final String? uuid;

  Person({required this.name, required this.age, uuid})
      : uuid = uuid ?? const Uuid().v4();

  Person updated([String? name, int? age]) {
    final newPerson = Person(
      name: name ?? this.name,
      age: age ?? this.age,
      uuid: uuid,
    );
    return newPerson;
  }

  @override
  bool operator ==(covariant Person other) => uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  String get displayName => '$name  ($age years old)';

  @override
  String toString() {
    return 'Person is name: $name , age: $age';
  }
}

class ModelPerson extends ChangeNotifier {
  final List<Person> _people = [];
  UnmodifiableListView<Person> get people => UnmodifiableListView(_people);

  int get count => _people.length;

  void add(Person person) {
    _people.add(person);
    notifyListeners();
  }

  void update(Person updatedPerson) {
    final index = _people.indexOf(updatedPerson);

    final oldPerson = _people[index];

    if (oldPerson.name != updatedPerson.name ||
        oldPerson.age != updatedPerson.age) {
      _people[index] = oldPerson.updated(
        updatedPerson.name,
        updatedPerson.age,
      );
      notifyListeners();
    }
  }
}

final personProvider = ChangeNotifierProvider<ModelPerson>((ref) {
  return ModelPerson();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final personModel = ref.watch(personProvider);
    Person person;
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomePage'),
      ),
      body: Expanded(
        child: ListView.builder(
          itemCount: personModel.count,
          itemBuilder: ((context, index) {
            final person = personModel.people[index];

            return ListTile(
              title: GestureDetector(
                onTap: () async {
                  final updatedPerson = await personDialogue(context, person);
                  if (updatedPerson != null) {
                    personModel.update(updatedPerson);
                  }
                },
                child: Text(person.displayName),
              ),
            );
          }),
        ),
      ),
      floatingActionButton: IconButton(
          onPressed: () async {
            final createPerson = await personDialogue(context);
            if (createPerson != null) {
              personModel.add(createPerson);
            }
          },
          icon: const Icon(Icons.add)),
    );
  }
}

Future<Person?> personDialogue(context, [Person? person]) {
  String? personName = person?.name;
  int? personAge = person?.age;
  final name = TextEditingController();
  final age = TextEditingController();
  final ageValue = int.tryParse(age.text);
  name.text = personName ?? '';
  age.text = personAge?.toString() ?? '';
  return showDialog<Person?>(
      context: context,
      builder: ((context) {
        return AlertDialog(
          title: const Text('create person '),
          content: Column(
            children: [
              TextField(
                decoration: const InputDecoration(hintText: "enter person "),
                controller: name,
                onChanged: (value) => personName = value,
              ),
              TextField(
                decoration: const InputDecoration(hintText: 'enter age'),
                controller: age,
                onChanged: (value) => personAge = int.tryParse(value),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                  if (personName != null && personAge != null) {
                    if (person != null) {
                      final newPerson = person.updated(personName, personAge);
                      Navigator.of(context).pop(newPerson);
                    } else {
                      Navigator.of(context)
                          .pop(Person(name: personName!, age: personAge!));
                    }
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('save')),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("cancel"))
          ],
        );
      }));
}
