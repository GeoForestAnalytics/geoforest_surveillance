// Arquivo: lib/data/datasources/local/database_helper.dart (VERSÃO CORRIGIDA E ATUALIZADA)

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
      // >> MUDANÇA 9: VERSÃO DO BANCO ATUALIZADA PARA 4 <<
      // =======================================================
      version: 4,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async => await db.execute('PRAGMA foreign_keys = ON');

  Future<void> _onCreate(Database db, int version) async {
    // Este método agora cria o banco de dados já na versão 4
    
    // =======================================================
    // >> MUDANÇA 10: TABELA 'campanhas' COM CAMPO 'tipo' <<
    // =======================================================
    await db.execute('''
      CREATE TABLE campanhas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        licenseId TEXT NOT NULL,
        nome TEXT NOT NULL,
        orgaoResponsavel TEXT NOT NULL,
        tipoCampanha TEXT NOT NULL DEFAULT 'dengue',
        dataCriacao TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'ativa'
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

    // =======================================================
    // >> MUDANÇA 11: NOVA TABELA 'imoveis' PARA O CADASTRO FIXO <<
    // =======================================================
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
        
        -- Campos socioeconômicos
        quantidadeMoradores INTEGER,
        rendaFamiliar REAL,
        
        -- Outros dados fixos
        dataCadastro TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0 NOT NULL,
        FOREIGN KEY (bairroId) REFERENCES bairros (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_imoveis_bairroId ON imoveis(bairroId)');

    // =======================================================
    // >> MUDANÇA 12: NOVA TABELA 'visitas' PARA OS EVENTOS <<
    // =======================================================
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
        
        -- Campo flexível para armazenar dados do formulário específico da campanha
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

    // A tabela 'focos' é mantida para compatibilidade, mas novas vistorias
    // serão salvas em 'visitas'.
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

    // =======================================================
    // >> MUDANÇA 13: LÓGICA DE MIGRAÇÃO PARA A VERSÃO 4 <<
    // =======================================================
    if (oldVersion < 4) {
      // Adiciona o campo de tipo de campanha
      await db.execute("ALTER TABLE campanhas ADD COLUMN tipoCampanha TEXT NOT NULL DEFAULT 'dengue'");

      // Cria a nova tabela de imóveis
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

      // Cria a nova tabela de visitas
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