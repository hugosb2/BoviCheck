import flet as ft

VERSION_NUMBER = "0.9.9"
BUILD_TAG = "Stable"

INDICES = [
    {
        "Índice": "Taxa de Natalidade",
        "Conceito": "A porcentagem de bezerros nascidos vivos em relação ao número de fêmeas aptas (expostas à reprodução) em um determinado período.",
        "Inputs": "Número de bezerros nascidos vivos, Número total de fêmeas aptas (expostas à reprodução)"
    },
    {
        "Índice": "Taxa de Desmame",
        "Conceito": "A porcentagem de bezerros desmamados em relação ao número de bezerros nascidos vivos ou ao número de fêmeas que pariram.",
        "Inputs": "Número de bezerros desmamados, Número de bezerros nascidos vivos no período"
    },
    {
        "Índice": "Ganho Médio Diário (GMD)",
        "Conceito": "A média de peso que um animal ou lote de animais ganha por dia durante um período específico. Essencial para avaliar o desenvolvimento em todas as fases (cria, recria e engorda).",
        "Inputs": "Peso inicial (kg), Peso final (kg), Nº de dias entre pesagens"
    },
    {
        "Índice": "Peso ao Desmame Ajustado P205",
        "Conceito": "Padroniza o peso dos bezerros à desmama para uma idade comum (geralmente 205 dias para corte), permitindo comparações mais justas entre animais.",
        "Inputs": "Peso ao nascer (kg), Peso real à desmama (kg), Idade real à desmama (dias)"
    },
    {
        "Índice": "Taxa de Mortalidade",
        "Conceito": "A porcentagem de animais que morreram em relação ao número total de animais em um determinado período ou fase de criação.",
        "Inputs": "Nº de animais mortos, Nº total de animais existentes no início do período/fase"
    },
    {
        "Índice": "Lotação Animal",
        "Conceito": "A relação entre a quantidade de Unidades Animais (UA, onde 1 UA = 450 kg de peso vivo) e a área de pastagem disponível. Indica a pressão de pastejo.",
        "Inputs": "Número total de animais, Peso vivo médio por animal (kg), Área total de pastagem (ha)"
    },
    {
        "Índice": "Produção de Leite por Vaca/Dia",
        "Conceito": "A média da quantidade de leite produzida por cada vaca em lactação, por dia.",
        "Inputs": "Produção total de leite no dia (L), Número de vacas em lactação"
    },
    {
        "Índice": "Idade ao Primeiro Parto",
        "Conceito": "A idade média das novilhas quando parem pela primeira vez. Influencia os custos de criação da novilha e o início da sua vida produtiva.",
        "Inputs": "Data de nascimento da novilha (dd/mm/aaaa), Data do primeiro parto da novilha (dd/mm/aaaa)"
    },
    {
        "Índice": "Intervalo entre Partos",
        "Conceito": "O período médio, em meses ou dias, entre dois partos consecutivos de uma mesma vaca. Impacta diretamente a eficiência reprodutiva.",
        "Inputs": "Data do parto anterior (dd/mm/aaaa), Data do parto atual (dd/mm/aaaa)"
    },
    {
        "Índice": "Taxa de Prenhez",
        "Conceito": "A porcentagem de fêmeas que emprenham em relação ao número total de fêmeas aptas expostas à reprodução dentro de um período definido.",
        "Inputs": "Número de fêmeas diagnosticadas prenhes, Número total de fêmeas aptas (expostas)"
    },
    {
        "Índice": "Conversão Alimentar",
        "Conceito": "Quantidade de alimento (Matéria Seca) necessária para cada kg de ganho de peso vivo.",
        "Inputs": "Consumo de matéria seca (MS em kg), Ganho de peso vivo (PV em kg)"
    },
    {
        "Índice": "Rendimento de Carcaça",
        "Conceito": "Percentual do peso vivo do animal que é convertido em carcaça após o abate.",
        "Inputs": "Peso vivo antes do abate (kg), Peso da carcaça (kg)"
    }
]

APPBAR_SHORT_NAMES = {
    "Taxa de Natalidade": "Natalidade", "Taxa de Desmame": "Desmame",
    "Ganho Médio Diário (GMD)": "GMD", "Peso ao Desmame Ajustado P205": "Peso Ajustado",
    "Taxa de Mortalidade": "Mortalidade", "Lotação Animal": "Lotação",
    "Produção de Leite por Vaca/Dia": "Prod. Leite", "Idade ao Primeiro Parto": "IPP",
    "Intervalo entre Partos": "IEP", "Taxa de Prenhez": "Prenhez",
    "Conversão Alimentar": "Conv. Alimentar", "Rendimento de Carcaça": "Rend. Carcaça"
}

AVAILABLE_COLOR_SEEDS_WITH_NAMES = [
    {"name": "Verde-azulado (Padrão)", "value": "TEAL_ACCENT_700", "color_obj": ft.Colors.TEAL_ACCENT_700},
    {"name": "Azul", "value": "BLUE_ACCENT_700", "color_obj": ft.Colors.BLUE_ACCENT_700},
    {"name": "Vermelho", "value": "RED_ACCENT_700", "color_obj": ft.Colors.RED_ACCENT_700},
    {"name": "Verde", "value": "GREEN_ACCENT_700", "color_obj": ft.Colors.GREEN_ACCENT_700},
    {"name": "Laranja", "value": "ORANGE_ACCENT_700", "color_obj": ft.Colors.ORANGE_ACCENT_700},
    {"name": "Roxo", "value": "PURPLE_ACCENT_700", "color_obj": ft.Colors.PURPLE_ACCENT_700},
    {"name": "Índigo", "value": "INDIGO_ACCENT_700", "color_obj": ft.Colors.INDIGO_ACCENT_700},
    {"name": "Âmbar", "value": "AMBER_ACCENT_700", "color_obj": ft.Colors.AMBER_ACCENT_700},
    {"name": "Ciano", "value": "CYAN_ACCENT_700", "color_obj": ft.Colors.CYAN_ACCENT_700},
    {"name": "Rosa", "value": "PINK_ACCENT_700", "color_obj": ft.Colors.PINK_ACCENT_700},
    {"name": "Marrom", "value": "BROWN", "color_obj": ft.Colors.BROWN},
    {"name": "Cinza Azulado", "value": "BLUE_GREY", "color_obj": ft.Colors.BLUE_GREY},
]