SYSTEM_INSTRUCTION = "Você é um assistente especialista em agropecuária e análise de dados zootécnicos."

DASHBOARD_SUGGESTION_PROMPT = """Aja como um consultor agropecuário paciente e didático, falando com um produtor que está começando. Com base no resumo de dados a seguir, forneça uma sugestão clara e simples, explicando o porquê da sugestão de forma fácil de entender. Evite jargões técnicos."""

IMAGE_ANALYSIS_PROMPT = "Descreva esta imagem em detalhes. Se houver elementos relacionados à agropecuária, zootecnia ou saúde animal (como gado, pastagens, equipamentos, condições corporais de animais), foque sua análise nesses pontos."

def get_document_analysis_prompt(filename: str, file_content: str, caption: str) -> str:
    """Gera o prompt para quando o conteúdo de um documento é enviado para análise, com uma legenda opcional."""
    if "não é suportada" in file_content or "não foi possível ler" in file_content:
        return f"O usuário anexou o arquivo '{filename}', mas não foi possível extrair seu conteúdo. Informe ao usuário que o formato pode não ser suportado ou o arquivo pode estar corrompido, e pergunte se ele pode fornecer o conteúdo de outra forma."
    
    if not caption:
        user_instruction = "Analise o seguinte conteúdo extraído deste arquivo e forneça um resumo, insights ou pontos chave relevantes."
    else:
        user_instruction = f"Com base na seguinte pergunta/legenda do usuário: '{caption}', analise o conteúdo do arquivo abaixo e forneça uma resposta."

    return f"""O usuário anexou o arquivo chamado '{filename}'.
{user_instruction}

--- CONTEÚDO DO ARQUIVO ---
{file_content}
--- FIM DO CONTEÚDO ---
"""

def get_chat_user_question_prompt(user_text: str) -> str:
    """Gera o prompt que encapsula a pergunta do usuário para o chat."""
    return f"Com base no contexto de dados fornecido (se houver), responda à seguinte pergunta do usuário: {user_text}"

def get_index_suggestion_prompt(index_name: str) -> str:
    """Gera o prompt para a sugestão específica de um índice."""
    return f"""Aja como um consultor agropecuário paciente, explicando para um produtor leigo. Com base nos dados do índice '{index_name}' a seguir, forneça uma dica prática e fácil de implementar para melhorar este resultado. Explique em termos simples por que essa dica é importante."""