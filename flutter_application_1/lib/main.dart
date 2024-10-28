import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: LoginPage(),
    );
  }
}

class WelcomePage extends StatefulWidget {
  final String token_acceso;
  WelcomePage({required this.token_acceso});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _encargadoController = TextEditingController();
  final TextEditingController _contactoEncargadoController =
      TextEditingController();
  final TextEditingController _vertientesController = TextEditingController();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _latitudController = TextEditingController();
  final TextEditingController _longitudController = TextEditingController();

  // Lista para almacenar dispositivos encontrados
  List<BluetoothDevice> devicesList = [];

  // Función para escanear dispositivos Bluetooth
  void _scanForDevices() async {
    // Verifica si Bluetooth está encendido
    if (await FlutterBluePlus.isOn) {
      // Limpia la lista de dispositivos antes de escanear
      devicesList.clear();

      // Inicia el escaneo
      FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

      // Escucha los resultados del escaneo
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (!devicesList.contains(r.device)) {
            setState(() {
              devicesList.add(r.device);
            });
          }
        }
      });

      // Detiene el escaneo después del tiempo especificado
      await Future.delayed(Duration(seconds: 4));
      FlutterBluePlus.stopScan();

      // Muestra los dispositivos encontrados en un diálogo
      _showDevicesDialog();
    } else {
      // Solicita al usuario que encienda el Bluetooth
      await FlutterBluePlus.turnOn();
    }
  }

  // Función para mostrar los dispositivos en un diálogo
  void _showDevicesDialog() {
    // Inicia el escaneo al mostrar el diálogo
    FlutterBluePlus.startScan(timeout: Duration(seconds: 4));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dispositivos encontrados'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var devices = snapshot.data!;
                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      var device = devices[index].device;
                      return ListTile(
                        title: Text(device.name.isNotEmpty
                            ? device.name
                            : 'Dispositivo sin nombre'),
                        subtitle: Text(device.id.toString()),
                        onTap: () {
                          FlutterBluePlus.stopScan();
                          Navigator.pop(context);
                          _connectToDevice(device);
                        },
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reinicia el escaneo
                FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
              },
              child: Text('Reiniciar búsqueda'),
            ),
            TextButton(
              onPressed: () {
                // Detiene el escaneo y cierra el diálogo
                FlutterBluePlus.stopScan();
                Navigator.of(context).pop();
              },
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // Función para conectar al dispositivo seleccionado
  void _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conectado a ${device.name}')),
      );
      // Aquí puedes agregar lógica adicional después de la conexión
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar: $e')),
      );
    }
  }

  Future<void> _sendData() async {
    String token = widget.token_acceso;
    if (_formKey.currentState!.validate()) {
      // Mapa de datos a enviar
      Map<String, dynamic> data = {
        "nombre": _nombreController.text,
        "encargado": _encargadoController.text,
        "contacto_encargado": _contactoEncargadoController.text,
        "vertientes": _vertientesController.text.isNotEmpty
            ? int.parse(_vertientesController.text)
            : null,
        "ubicación": _ubicacionController.text,
        "latitud": _latitudController.text.isNotEmpty
            ? double.parse(_latitudController.text)
            : null,
        "longitud": _longitudController.text.isNotEmpty
            ? double.parse(_longitudController.text)
            : null,
      };

      var url =
          Uri.parse('http://192.168.1.90:8000/api/monitoreo/comunidades/');

      try {
        var response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: json.encode(data),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Datos enviados correctamente')),
          );
          // Limpiar los campos del formulario
          _formKey.currentState!.reset();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al enviar datos: ${response.statusCode}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Liberar los controladores
    _nombreController.dispose();
    _encargadoController.dispose();
    _contactoEncargadoController.dispose();
    _vertientesController.dispose();
    _ubicacionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Formulario de Datos"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("¡Bienvenido a la aplicación!",
                  style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _encargadoController,
                decoration: InputDecoration(labelText: 'Encargado'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el encargado';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _contactoEncargadoController,
                decoration: InputDecoration(labelText: 'Contacto Encargado'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el contacto del encargado';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _vertientesController,
                decoration: InputDecoration(labelText: 'Vertientes'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _ubicacionController,
                decoration: InputDecoration(labelText: 'Ubicación'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la ubicación';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _latitudController,
                decoration: InputDecoration(labelText: 'Latitud'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _longitudController,
                decoration: InputDecoration(labelText: 'Longitud'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _sendData,
                child: Text('Enviar Datos'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _scanForDevices,
                child: Text('Conectar Dispositivo Bluetooth'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      var response = await http.post(
        Uri.parse(
            'http://192.168.1.90:8000/api/token/'), // Cambia a la URL de tu API
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
      );

      // URL de AWS LAMBDA para pruebas varias...
      //https://6dpondtlbb.execute-api.us-east-1.amazonaws.com/prod/login

      final Map<String, dynamic> body = jsonDecode(response.body);
      var token_acceso = body['access'];

      if (response.statusCode == 200) {
        // Si el servidor devuelve una respuesta OK, navega a la siguiente pantalla
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WelcomePage(token_acceso: token_acceso)),
        );
      } else if (response.statusCode == 401) {
        // Credenciales inválidas
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Credenciales inválidas')),
        );
      } else {
        // Si la respuesta no fue OK, muestra un error
        // Otros errores
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var token_acceso = '23131321';
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                    labelText: 'RUT del usuario', hintText: '12345678-9'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu RUT';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                    labelText: 'Contraseña', hintText: 'Ingresa tu contraseña'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navegar directamente a la WelcomePage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WelcomePage(token_acceso: token_acceso),
                    ),
                  );
                },
                child: Text('Ingresar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
