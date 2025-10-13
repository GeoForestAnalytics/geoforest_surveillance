// Arquivo: lib\models\municipio_model.dart
class Municipio {
final String id; // Pode ser o código IBGE ou o nome
final int acaoId;
final String nome;
final String uf; // Sigla do estado, ex: SP
Municipio({
required this.id,
required this.acaoId,
required this.nome,
required this.uf,
});
Map<String, dynamic> toMap() {
return {
'id': id,
'acaoId': acaoId,
'nome': nome,
'uf': uf,
};
}
factory Municipio.fromMap(Map<String, dynamic> map) {
return Municipio(
id: map['id'],
acaoId: map['acaoId'],
nome: map['nome'],
uf: map['uf'],
);
}
}