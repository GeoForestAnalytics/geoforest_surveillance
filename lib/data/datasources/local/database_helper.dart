// Arquivo: lib/data/datasources/local/database_helper.dart (VERSÃO CORRIGIDA E FINAL)

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // Configuração do Singleton
  static final DatabaseHelper _instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();
  factory DatabaseHelper() => _instance;
  
  static DatabaseHelper get instance => _instance; 

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'geo_dengue_monitor.db'),
      // =======================================================
      // >> MUDANÇA 1: VERSÃO DO BANCO ATUALIZADA PARA 5 <<
      // =======================================================
      version: 5, 
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async => await db.execute('PRAGMA foreign_keys = ON');

  Future<void> _onCreate(Database db, int version) async {
    // Este método agora cria o banco de dados já na versão 5
    
    await db.execute('''
      CREATE TABLE campanhas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        licenseId TEXT NOT NULL,
        nome TEXT NOT NULL,
        orgaoResponsavel TEXT NOT NULL,
        tipoCampanha TEXT NOT NULL DEFAULT 'dengue',
        dataCriacao TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ativa',
        -- =======================================================
        -- >> MUDANÇA 2: COLUNAS ADICIONADAS AQUI (CORREÇÃO DO ERRO) <<
        -- =======================================================
        responsavelTecnico TEXT,
        corSetor TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE postos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        licenseId TEXT NOT NULL,
        nome TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        UNIQUE(licenseId, nome)
      )
    ''');
    
    await db.execute('''
      CREATE TABLE acoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        campanhaId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        descricao TEXT,
        dataCriacao TEXT NOT NULL,
        FOREIGN KEY (campanhaId) REFERENCES campanhas (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE municipios (
        id TEXT NOT NULL,
        acaoId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        uf TEXT NOT NULL,
        PRIMARY KEY (id, acaoId),
        FOREIGN KEY (acaoId) REFERENCES acoes (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bairros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        municipioId TEXT NOT NULL,
        acaoId INTEGER NOT NULL,
        postoId INTEGER,
        nome TEXT NOT NULL,
        responsavelSetor TEXT,
        geometria TEXT,
        FOREIGN KEY (municipioId, acaoId) REFERENCES municipios (id, acaoId) ON DELETE CASCADE,
        FOREIGN KEY (postoId) REFERENCES postos (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE imoveis (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        bairroId INTEGER,
        logradouro TEXT NOT NULL,
        numero TEXT,
        complemento TEXT,
        cep TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        tipoImovel TEXT,
        quantidadeMoradores INTEGER,
        rendaFamiliar REAL,
        dataCadastro TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0 NOT NULL,
        FOREIGN KEY (bairroId) REFERENCES bairros (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_imoveis_bairroId ON imoveis(bairroId)');

    await db.execute('''
      CREATE TABLE visitas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        imovelId INTEGER NOT NULL,
        campanhaId INTEGER NOT NULL,
        acaoId INTEGER NOT NULL,
        dataVisita TEXT NOT NULL,
        nomeAgente TEXT NOT NULL,
        nomeResponsavelAtendimento TEXT,
        dadosFormulario TEXT,
        photoPaths TEXT,
        observacao TEXT,
        isSynced INTEGER DEFAULT 0 NOT NULL,
        FOREIGN KEY (imovelId) REFERENCES imoveis (id) ON DELETE CASCADE,
        FOREIGN KEY (campanhaId) REFERENCES campanhas (id) ON DELETE CASCADE,
        FOREIGN KEY (acaoId) REFERENCES acoes (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_visitas_imovelId ON visitas(imovelId)');
    await db.execute('CREATE INDEX idx_visitas_campanhaId ON visitas(campanhaId)');

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
        recipientes TEXT,
        amostrasColetadas INTEGER,
        tratamentoRealizado TEXT,
        observacao TEXT,
        photoPaths TEXT,
        nomeAgente TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0 NOT NULL,
        FOREIGN KEY (bairroId) REFERENCES bairros (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_focos_bairroId ON focos(bairroId)');
    await db.execute('CREATE INDEX idx_focos_campanhaId ON focos(campanhaId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Executa as migrações passo a passo
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE postos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          licenseId TEXT NOT NULL,
          nome TEXT NOT NULL,
          UNIQUE(licenseId, nome)
        )
      ''');
      await db.execute('ALTER TABLE bairros ADD COLUMN postoId INTEGER REFERENCES postos(id) ON DELETE SET NULL');
      await db.execute('ALTER TABLE bairros ADD COLUMN geometria TEXT');
    }
    
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE postos ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE postos ADD COLUMN longitude REAL');
    }

    if (oldVersion < 4) {
      await db.execute("ALTER TABLE campanhas ADD COLUMN tipoCampanha TEXT NOT NULL DEFAULT 'dengue'");
      await db.execute('''
        CREATE TABLE imoveis (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          bairroId INTEGER,
          logradouro TEXT NOT NULL,
          numero TEXT,
          complemento TEXT,
          cep TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          tipoImovel TEXT,
          quantidadeMoradores INTEGER,
          rendaFamiliar REAL,
          dataCadastro TEXT NOT NULL,
          isSynced INTEGER DEFAULT 0 NOT NULL,
          FOREIGN KEY (bairroId) REFERENCES bairros (id) ON DELETE SET NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_imoveis_bairroId ON imoveis(bairroId)');
      await db.execute('''
        CREATE TABLE visitas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uuid TEXT NOT NULL UNIQUE,
          imovelId INTEGER NOT NULL,
          campanhaId INTEGER NOT NULL,
          acaoId INTEGER NOT NULL,
          dataVisita TEXT NOT NULL,
          nomeAgente TEXT NOT NULL,
          nomeResponsavelAtendimento TEXT,
          dadosFormulario TEXT,
          photoPaths TEXT,
          observacao TEXT,
          isSynced INTEGER DEFAULT 0 NOT NULL,
          FOREIGN KEY (imovelId) REFERENCES imoveis (id) ON DELETE CASCADE,
          FOREIGN KEY (campanhaId) REFERENCES campanhas (id) ON DELETE CASCADE,
          FOREIGN KEY (acaoId) REFERENCES acoes (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_visitas_imovelId ON visitas(imovelId)');
      await db.execute('CREATE INDEX idx_visitas_campanhaId ON visitas(campanhaId)');
    }

    // =======================================================
    // >> MUDANÇA 3: LÓGICA DE MIGRAÇÃO PARA A VERSÃO 5 (CORREÇÃO DO ERRO) <<
    // =======================================================
    if (oldVersion < 5) {
      // Adiciona as colunas que estavam faltando na tabela de campanhas
      await db.execute("ALTER TABLE campanhas ADD COLUMN responsavelTecnico TEXT");
      await db.execute("ALTER TABLE campanhas ADD COLUMN corSetor TEXT");
    }
  }
  
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