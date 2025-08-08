// Arquivo: lib\data\datasources\local\database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();
  factory DatabaseHelper() => _instance;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'geo_dengue_monitor.db'), // Novo nome do arquivo de banco
      version: 1, // Comece com a versão 1 para a nova estrutura
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      // onUpgrade pode ser deixado em branco por enquanto, já que estamos recriando
    );
  }

  Future<void> _onConfigure(Database db) async => await db.execute('PRAGMA foreign_keys = ON');

  // A MUDANÇA PRINCIPAL: Nova estrutura de tabelas
  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabela de Campanhas (antiga 'projetos')
    await db.execute('''
      CREATE TABLE campanhas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        licenseId TEXT NOT NULL,
        nome TEXT NOT NULL,
        orgaoResponsavel TEXT NOT NULL,
        dataCriacao TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ativa'
      )
    ''');

    // 2. Tabela de Ações (antiga 'atividades')
    await db.execute('''
      CREATE TABLE acoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campanhaId INTEGER NOT NULL,
        tipo TEXT NOT NULL, -- Ex: "Visita de Agentes", "Mutirão de Limpeza"
        descricao TEXT,
        dataCriacao TEXT NOT NULL,
        FOREIGN KEY (campanhaId) REFERENCES campanhas (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabela de Municípios (antiga 'fazendas')
    await db.execute('''
      CREATE TABLE municipios (
        id TEXT NOT NULL, -- Código IBGE ou nome, como preferir
        acaoId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        uf TEXT NOT NULL,
        PRIMARY KEY (id, acaoId),
        FOREIGN KEY (acaoId) REFERENCES acoes (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabela de Bairros (antiga 'talhoes')
    await db.execute('''
      CREATE TABLE bairros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        municipioId TEXT NOT NULL,
        acaoId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        responsavelSetor TEXT,
        FOREIGN KEY (municipioId, acaoId) REFERENCES municipios (id, acaoId) ON DELETE CASCADE
      )
    ''');

    // 5. Tabela de Focos (nova, substitui 'parcelas' e 'arvores')
    await db.execute('''
      CREATE TABLE focos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        bairroId INTEGER NOT NULL,
        campanhaId INTEGER NOT NULL,
        endereco TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        dataVisita TEXT NOT NULL,
        tipoLocal TEXT NOT NULL,
        statusFoco TEXT NOT NULL,
        recipientes TEXT, -- Lista separada por vírgula. Ex: "pneu,vaso,caixa"
        amostrasColetadas INTEGER,
        tratamentoRealizado TEXT,
        observacao TEXT,
        photoPaths TEXT, -- Lista de caminhos de fotos, separada por vírgula
        nomeAgente TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0 NOT NULL,
        FOREIGN KEY (bairroId) REFERENCES bairros (id) ON DELETE CASCADE
      )
    ''');
    
    // Índices para acelerar as buscas
    await db.execute('CREATE INDEX idx_focos_bairroId ON focos(bairroId)');
    await db.execute('CREATE INDEX idx_focos_campanhaId ON focos(campanhaId)');
  }

  // Função para apagar o banco de dados completamente (útil durante o desenvolvimento)
  Future<void> deleteDatabaseFile() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
    try {
      final path = join(await getDatabasesPath(), 'geo_dengue_monitor.db');
      await deleteDatabase(path);
      print("Banco de dados local completamente apagado com sucesso.");
    } catch (e) {
      print("ERRO AO APAGAR O BANCO DE DADOS: $e");
      rethrow;
    }
  }
}