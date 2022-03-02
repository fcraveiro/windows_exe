import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase/supabase.dart';
import 'model_stream.dart';

class Stream extends StatefulWidget {
  const Stream({Key? key}) : super(key: key);

  @override
  _StreamState createState() => _StreamState();
}

int c = 0;
const supabaseUrl = '';
const supabaseKey = '';

final client = SupabaseClient(supabaseUrl, supabaseKey);

class _StreamState extends State<Stream> {
  final TextEditingController _textFieldController = TextEditingController();
  List<ClassStream> lista = [];
  var pathServer = '';

  @override
  Widget build(BuildContext context) {
    final ScrollController controller = ScrollController();
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 0,
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: client
                        .from('aula')
                        .stream(['streamUuId'])
                        .order('streamData', ascending: false)
                        .execute()
                        .handleError((e) => {
                              dev.log('erro $e'),
                            }),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Text('Erro');
                      } else {
                        lista = [];
                        for (var data in snapshot.data!) {
                          lista.add(ClassStream.fromJson(data));
                        }

                        return ListView.builder(
                          controller: controller,
                          itemCount: lista.length,
                          itemBuilder: (BuildContext context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    lista[index]
                                        .streamNome
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                  ),
                                ),
                                title: Text(
                                  lista[index].streamNome.toString(),
                                ),
                                trailing: Image.network(
                                  lista[index].streamThumbUrl,
                                ),
                              ),
                            );
                          },
                        );
                      }
                    }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => {
          _inputDialog(),
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _inputDialog() async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Digite o Nome'),
            content: TextField(
              onChanged: (value) {},
              controller: _textFieldController,
              decoration: const InputDecoration(hintText: "Nome"),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  _textFieldController.clear();
                  Navigator.pop(context);
                },
              ),
              ElevatedButton(
                child: const Text('OK'),
                onPressed: () {
                  grava(_textFieldController.text);
                  _textFieldController.clear();
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  grava(nome) async {
    await imagemFromAsset('foto1.jpg');
    final campos = ClassStream(
      streamNome: nome,
      streamFotoUrl: pathServer,
      streamThumbUrl: pathServer,
    );
    Map<String, dynamic> aulaJson = campos.toJson();
    dev.log(aulaJson.toString());
    await client
        .from('aula')
        .insert(aulaJson)
        .execute()
        .then((value) => dev.log(value.error.toString()));
  }

  imagemFromAsset(String path) async {
    var fotinho = escolheFoto();
    final byteData = await rootBundle.load(fotinho);
    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    dev.log(file.path.toString());
    //
    DateTime now = DateTime.now();
    var idFoto = now.toString() + '.jpg';
    await client.storage.from('fotos').upload(idFoto, file).then(
      (value) {
        var response = client.storage.from('fotos').getPublicUrl(idFoto);
        pathServer = response.data.toString();
      },
    );
  }
}

escolheFoto() {
  var gg = random(1, 7).toString();
  String fotinho1 = 'assets/imagens/foto';
  String fotinho2 = '.jpg';
  c = int.parse(gg);
  String fotona = fotinho1 + c.toString() + fotinho2;
  dev.log('FOTONA = ${fotona.toString()}');
  return fotona;
}

random(min, max) {
  var rn = Random();
  return min + rn.nextInt(max - min);
}
