import 'modelo_documento.dart';

/// Base de conhecimento estática para RAG.
/// Em produção, pode vir de SQLite/arquivo JSON ou remote.
/// Cada documento é um chunk ~200-400 tokens sobre manejo pecuário.
class BaseConhecimento {
  static const List<DocumentoRAG> documentos = [
    DocumentoRAG(
      id: 'gmd_001',
      titulo: 'Ganho Médio Diário (GMD) - Bezerros de Corte',
      categoria: 'Nutrição/Crescimento',
      fonte: 'Embrapa Gado de Corte - Comunicado Técnico 85',
      tags: ['gmd', 'ganho', 'peso', 'bezerro', 'suplementação', 'desmama'],
      conteudo:
          'GMD ideal para bezerros Nelore do nascimento à desmama (7-8 meses) é 0,70-0,90 kg/dia. '
          'GMD <0,50 kg/dia indica déficit proteico-energético ou verminose. '
          'Fatores críticos: creep-feeding (0,5-1% PV), controle de endo/ectoparasitas, água de qualidade. '
          'Pesagens a cada 30 dias permitem detectar queda precoce. GMD baixo correlaciona com mortalidade >3%.',
    ),
    DocumentoRAG(
      id: 'iep_001',
      titulo: 'Intervalo Entre Partos (IEP) - Eficiência Reprodutiva',
      categoria: 'Reprodução',
      fonte: 'Manual de Reprodução Bovina - CBRA 2023',
      tags: ['iep', 'reprodução', 'parto', 'prenhez', 'intervalo', 'vaca'],
      conteudo:
          'IEP ideal para gado de corte é 12-13 meses (365-390 dias). IEP 14-16 meses = atenção, >16 meses = ruim. '
          'Causas de IEP longo: escore corporal <2,75 no parto, anestro pós-parto >80 dias, estação de monta >90 dias. '
          'Soluções: IATF + ressincronização, desmame precoce (90 dias) ou interrompido 48h, suplementação pré-parto. '
          'Taxa de prenhez alvo: >85% diagnóstico positivo, <70% indica falha no protocolo.',
    ),
    DocumentoRAG(
      id: 'natal_001',
      titulo: 'Taxa de Natalidade e Prenhez em Gado de Corte',
      categoria: 'Reprodução',
      fonte: 'Anualpec 2024 - Indicadores Zootécnicos',
      tags: ['natalidade', 'prenhez', 'nascimento', 'fertilidade', 'fêmea'],
      conteudo:
          'Taxa de natalidade = nascimentos / fêmeas aptas (>24 meses) *100. Alvo >80% bom, 60-80% atenção, <60% ruim. '
          'Taxa de prenhez = positivas / diagnósticos *100. Alvo >85%. Natalidade baixa geralmente reflete falha na estação de monta, '
          'touro subfértil ou déficit nutricional. Avaliar exame andrológico e escore corporal das matrizes.',
    ),
    DocumentoRAG(
      id: 'mortal_001',
      titulo: 'Mortalidade Neonatal e Geral - Limiares Críticos',
      categoria: 'Sanidade',
      fonte: 'MAPA - Programa Nacional de Sanidade Bovina',
      tags: ['mortalidade', 'morte', 'óbito', 'sanidade', 'bezerro', 'diarreia'],
      conteudo:
          'Mortalidade geral anual alvo <3% bom, 3-5% atenção, >5% ruim/crítico. Mortalidade neonatal (0-30 dias) deve ser <5%. '
          'Principais causas: diarreia neonatal (E. coli, rota/coronavírus), pneumonia, tristeza parasitária. '
          'Prevenção: colostragem <6h, cura de umbigo com iodo 10%, vacinação de matrizes (clostridioses, IBR/BVD). '
          'Mortalidade >5% exige investigação: necropsia, coproparasitológico e ajuste de manejo.',
    ),
    DocumentoRAG(
      id: 'desmame_001',
      titulo: 'Taxa de Desmame e Idade ao Primeiro Parto',
      categoria: 'Reprodução/Crescimento',
      fonte: 'Embrapa - Sistema de Produção de Gado de Corte',
      tags: ['desmame', 'desmama', 'ipp', 'primeiro parto', 'novilha'],
      conteudo:
          'Taxa de desmame alvo >85% (bezerros desmamados / nascidos). <50% crítico. Idade ao primeiro parto (IPP) ideal 24-30 meses, '
          '30-36 meses atenção, >36 meses ruim (atraso genético/nutricional). Para IPP 24 meses, novilha deve ganhar 0,60 kg/dia do desmame à puberdade (300kg). '
          'Suplementação proteica na seca e estação de monta de novilhas aos 14 meses com IATF.',
    ),
    DocumentoRAG(
      id: 'leite_001',
      titulo: 'Produção de Leite - Média por Vaca/Dia no Trópico',
      categoria: 'Leite',
      fonte: 'Embrapa Gado de Leite - Circular Técnica 112',
      tags: ['leite', 'produção', 'litros', 'ordenha', 'vaca leiteira'],
      conteudo:
          'Média tropical: Girolando 12-18 L/vaca/dia (2 ordenhas), Holandesa confinada 25-35 L/dia. '
          'Queda >15% no mês indica mastite subclínica, estresse térmico ou déficit energético. '
          'Manejo: ordenha higiênica (pré/pós-dipping), CCS <400k, intervalo 12h, sombra + ventilação. '
          'Registrar litros por período (manhã/tarde) permite detectar vaca com queda precoce.',
    ),
    DocumentoRAG(
      id: 'sanit_001',
      titulo: 'Calendário Sanitário Básico - Corte e Leite',
      categoria: 'Sanidade',
      fonte: 'CRMV-MS - Calendário Sanitário 2024',
      tags: ['vacina', 'vacinação', 'sanitário', 'aftosa', 'clostridiose', 'vermifugo'],
      conteudo:
          'Vacinas obrigatórias: Aftosa (maio/novembro), Brucelose (bezerras 3-8m), Raiva em área endêmica. '
          'Clostridioses: 1ª dose 4m + reforço 30d + anual. Vermifugação estratégica: entrada seca, meio seca, início chuvas (exame OPG). '
          'Bezerros com GMD baixo + pelo arrepiado = verminose. Tristeza parasitária: controle de carrapato (banho 21d) + vacina.',
    ),
    DocumentoRAG(
      id: 'nutri_001',
      titulo: 'Suplementação na Seca - Estratégia para GMD',
      categoria: 'Nutrição',
      fonte: 'UFV - Suplementação de Bovinos a Pasto',
      tags: ['suplementação', 'proteinado', 'seca', 'pasto', 'cocho', 'gmd'],
      conteudo:
          'Na seca, pasto cai para 5-7% PB; suplementação proteica (30-40% PB) 0,2-0,3% PV mantém GMD 0,30 kg/dia vs perda de peso. '
          'Proteinado energético (20% PB + 60% NDT) para recria: 0,5% PV. Sal mineral: 30g/cab/dia. '
          'Piquetes com lotação >1 UA/ha na seca sem suplemento causam GMD negativo e mortalidade. Avaliar oferta de forragem (kg MS/ha).',
    ),
    DocumentoRAG(
      id: 'piquete_001',
      titulo: 'Manejo de Piquetes e Lotação',
      categoria: 'Pastagem',
      fonte: 'Embrapa - Manejo de Pastagens Tropicais',
      tags: ['piquete', 'pasto', 'lotação', 'capacidade', 'pastejo', 'hectare'],
      conteudo:
          'Capacidade de suporte: Brachiaria brizantha 1,5-2,5 UA/ha nas águas, 0,5-0,8 UA/ha na seca sem suplemento. '
          'Pastejo rotacionado: altura entrada 30cm, saída 15cm (Mombaça). Lotação acima do suporte causa degradação e baixo peso. '
          'Área útil vs total: considerar 70-80% aproveitável (APP, reserva). Piquete maternidade deve ter sombra e água próxima.',
    ),
    DocumentoRAG(
      id: 'reprod_001',
      titulo: 'Diagnóstico de Gestação e Perdas Reprodutivas',
      categoria: 'Reprodução',
      fonte: 'Revista Brasileira de Reprodução Animal v47',
      tags: ['diagnóstico', 'gestação', 'perda', 'aborto', 'iatf'],
      conteudo:
          'Diagnóstico 30 dias pós-IATF (ultrassom). Perda embrionária 10-15% normal, >20% investigar IBR/BVD, leptospirose, neospora. '
          'Recomendação: vacinar 30 dias antes da estação, biossegurança (quarentena 30d para novos). '
          'Vacas vazias após 2 IATFs: descartar se >8 anos ou Escore <2,5.',
    ),
    DocumentoRAG(
      id: 'abate_001',
      titulo: 'Rendimento de Carcaça e Ponto de Abate',
      categoria: 'Abate/Terminação',
      fonte: 'ABIEC - Manual de Tipificação de Carcaças',
      tags: ['abate', 'carcaça', 'rendimento', 'peso vivo', 'terminação'],
      conteudo:
          'Rendimento alvo 52-55% (peso carcaça / peso vivo). <50% indica acabamento insuficiente. Peso vivo ideal abate: Nelore 520-580kg (18-24m). '
          'GMD na terminação confinada 1,4-1,7 kg/dia. Conversão alimentar 6-7:1. Monitorar dias de cocho e custo @.',
    ),
  ];
}
