import flet as ft
import requests
import uuid
from datetime import datetime
from models import persistence, prompts
import base64
import mimetypes
import os

try:
    import PyPDF2
    PDF_AVAILABLE = True
except ImportError:
    PDF_AVAILABLE = False

try:
    import docx
    DOCX_AVAILABLE = True
except ImportError:
    DOCX_AVAILABLE = False

try:
    import pandas as pd
    PANDAS_AVAILABLE = True
except ImportError:
    PANDAS_AVAILABLE = False


class AIController:
    def __init__(self, main_controller):
        self.main = main_controller
        self.page = main_controller.page
        self.app_state = main_controller.app_state

        self.main.ai_chat_messages_list = ft.ListView(expand=True, auto_scroll=True, spacing=10)
        self.main.ai_chat_input = ft.TextField(
            hint_text="Pergunte algo...", expand=True, on_submit=self.main.handle_send_ai_chat_message,
            border_radius=20, content_padding=12, border_color="outline",
            focused_border_color="primary", cursor_color="primary",
        )
        self.main.ai_chat_loading_indicator = ft.ProgressRing(visible=False, width=20, height=20, stroke_width=2.5)
        self.main.ai_chat_send_button = ft.IconButton(ft.Icons.SEND_ROUNDED, on_click=self.main.handle_send_ai_chat_message, tooltip="Enviar")
        self.main.ai_enabled_switch = ft.Switch(label="Habilitar IA (global)", on_change=self.main.handle_ai_enabled_change)
        self.main.ai_dashboard_switch = ft.Switch(label="Mostrar sugestões de IA no Dashboard e Índices", on_change=self.main.handle_ai_suggestions_change)
        self.main.rename_chat_dialog = None
        self.main.rename_chat_textfield = None
        self.main.chat_id_to_rename = None

    tools = [
        {
            "function_declarations": [
                {
                    "name": "importar_indices_da_planilha",
                    "description": "Usado quando o usuário pede para importar, adicionar ou carregar dados de uma planilha Excel que está ativa na conversa. Esta função não recebe argumentos, pois o aplicativo identifica automaticamente o arquivo em questão. A função lê a planilha e adiciona os registros ao aplicativo.",
                    "parameters": { "type": "OBJECT", "properties": {} }
                }
            ]
        }
    ]

    def _extract_text_from_file(self, file_path: str) -> str:
        _, file_extension = os.path.splitext(file_path)
        file_extension = file_extension.lower()
        try:
            if file_extension == ".txt":
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    return f.read()
            elif file_extension == ".pdf":
                if not PDF_AVAILABLE:
                    return "A extração de PDF não é suportada (biblioteca PyPDF2 não encontrada)."
                text = ""
                with open(file_path, "rb") as f:
                    reader = PyPDF2.PdfReader(f)
                    for page in reader.pages:
                        page_text = page.extract_text()
                        if page_text: text += page_text + "\n"
                return text
            elif file_extension == ".docx":
                if not DOCX_AVAILABLE:
                    return "A extração de DOCX não é suportada (biblioteca python-docx não encontrada)."
                doc = docx.Document(file_path)
                return "\n".join([para.text for para in doc.paragraphs])
            elif file_extension == ".xlsx":
                if not PANDAS_AVAILABLE:
                    return "A extração de XLSX não é suportada (biblioteca pandas não encontrada)."
                
                excel_file = pd.read_excel(file_path, sheet_name=None, engine='openpyxl')
                full_text = ""
                for sheet_name, df in excel_file.items():
                    full_text += f"--- Planilha: {sheet_name} ---\n"
                    full_text += df.to_markdown(index=False)
                    full_text += "\n\n"
                return full_text
            else:
                return f"A extração de conteúdo para arquivos '{file_extension}' não é suportada."
        except Exception as e:
            return f"Não foi possível ler o arquivo. Erro: {e}"

    def _handle_function_call(self, function_call: dict):
        function_name = function_call.get("name")
        
        if function_name == "importar_indices_da_planilha":
            from views.ai_view import _create_confirmation_control
            
            confirmation_control = _create_confirmation_control(
                text="A IA identificou dados compatíveis na planilha. Deseja importar estes registros para o seu Dashboard?",
                on_confirm=self.execute_confirmed_import,
                on_cancel=self.cancel_import
            )
            self.main.ai_chat_messages_list.controls.append(confirmation_control)
            self.page.update()
        else:
            error_message = f"A IA sugeriu uma função desconhecida: {function_name}"
            from views.ai_view import _create_chat_message_control
            cs = self.page.theme.color_scheme if self.page.theme else None
            self.main.ai_chat_messages_list.controls.append(
                _create_chat_message_control(error_message, "system", cs)
            )
            self.page.update()

    def execute_confirmed_import(self, e):
        active_file_path = self.app_state.active_file_in_chat.get("file_path")
        if not active_file_path or not PANDAS_AVAILABLE:
            result_message = "Erro: Arquivo da planilha não encontrado ou biblioteca pandas ausente."
        else:
            try:
                df = pd.read_excel(active_file_path, engine='openpyxl')
                items_added, result_message = self.main.data_controller.import_data_from_dataframe(df)
            except Exception as ex:
                result_message = f"Erro ao ler o arquivo Excel: {ex}"
        
        from views.ai_view import _create_chat_message_control
        cs = self.page.theme.color_scheme if self.page.theme else None
        self.main.ai_chat_messages_list.controls.append(
            _create_chat_message_control(result_message, "system", cs)
        )
        self.page.update()

    def cancel_import(self, e):
        from views.ai_view import _create_chat_message_control
        cs = self.page.theme.color_scheme if self.page.theme else None
        self.main.ai_chat_messages_list.controls.append(
            _create_chat_message_control("A importação foi cancelada pelo usuário.", "system", cs)
        )
        self.page.update()

    def handle_file_submission(self, file_path: str, caption: str):
        if not file_path: return
        if not self.app_state.current_chat_id: self.start_new_chat()
        current_chat = self.app_state.get_current_chat()
        if not current_chat: return

        self.app_state.active_file_in_chat = None
        self.main.ai_chat_loading_indicator.visible = True
        self.page.update()

        cs = self.page.theme.color_scheme if self.page.theme else None
        image_extensions = {".png", ".jpg", ".jpeg"}
        excel_extensions = {".xlsx"}
        file_ext = os.path.splitext(file_path)[1].lower()
        
        message_type = "image" if file_ext in image_extensions else "file"
        current_chat["messages"].append({"role": "user", "content": file_path, "type": message_type, "caption": caption})
        
        if message_type == "image":
            from views.ai_view import _create_image_message_control
            ui_control = _create_image_message_control(file_path, caption, "user", cs)
        else:
            from views.ai_view import _create_file_message_control
            ui_control = _create_file_message_control(file_path, "user", cs)
        
        self.main.ai_chat_messages_list.controls.append(ui_control)
        persistence.save_state(self.app_state)
        self.page.update()

        response, error = None, None
        if message_type == "image":
            try:
                with open(file_path, "rb") as image_file: image_data = image_file.read()
                base64_image = base64.b64encode(image_data).decode("utf-8")
                mime_type, _ = mimetypes.guess_type(file_path)
                if mime_type is None: mime_type = "application/octet-stream"
                prompt_text = caption if caption else prompts.IMAGE_ANALYSIS_PROMPT
                parts = [{"text": prompt_text}, {"inline_data": {"mime_type": mime_type, "data": base64_image}}]
                contents = {"contents": [{"parts": parts}]}
                response, error = self.call_gemini_api_sync(contents)
            except Exception as e:
                response, error = None, f"Erro ao processar a imagem: {e}"
        else:
            filename = os.path.basename(file_path)
            extracted_content = self._extract_text_from_file(file_path)
            self.app_state.active_file_in_chat = {
                "chat_id": current_chat["id"], "file_path": file_path, "content": extracted_content
            }
            prompt_text = prompts.get_document_analysis_prompt(filename, extracted_content, caption)
            contents = {"contents": [{"parts": [{"text": prompt_text}]}]}
            tools_payload = self.tools if file_ext in excel_extensions else None
            response, error = self.call_gemini_api_sync(contents, tools=tools_payload)

            if isinstance(response, dict):
                self._handle_function_call(response)
                response, error = None, None

        self.main.ai_chat_loading_indicator.visible = False
        
        if response:
            ai_content = response
            current_chat["messages"].append({"role": "ai", "content": ai_content, "type": "text"})
            from views.ai_view import _create_chat_message_control
            self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "ai", cs))
            persistence.save_state(self.app_state)
        elif error:
            ai_content = f"Erro: {error}"
            current_chat["messages"].append({"role": "system", "content": ai_content, "type": "text"})
            from views.ai_view import _create_chat_message_control
            self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "system", cs))
            persistence.save_state(self.app_state)

        self.page.update()

    def call_gemini_api_sync(self, contents: dict, tools: list | None = None) -> tuple[str | dict | None, str | None]:
        api_key = self.app_state.ai_settings.get("api_key")
        if not self.app_state.ai_settings.get("enabled") or not api_key:
            return None, "A funcionalidade de IA está desabilitada ou a chave de API não foi configurada."

        api_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key={api_key}"
        headers = {'Content-Type': 'application/json'}
        
        payload = contents.copy()
        if tools:
            payload["tools"] = tools

        try:
            response = requests.post(api_url, json=payload, headers=headers, timeout=60)
            response.raise_for_status()
            result = response.json()
            
            if "candidates" in result and result["candidates"]:
                candidate = result["candidates"][0]
                if candidate.get("content", {}).get("parts", [{}])[0].get("functionCall"):
                    fc = candidate["content"]["parts"][0]["functionCall"]
                    return fc, None
                
                if candidate.get("content", {}).get("parts"):
                    return candidate["content"]["parts"][0].get("text", "").strip(), None

            error_info = result.get('promptFeedback', result.get('error', {}))
            error_message = error_info.get('message', f"Resposta inválida da API: {error_info}")
            return None, error_message
        except requests.exceptions.HTTPError as http_err:
            return None, f"Erro HTTP: {http_err}."
        except requests.exceptions.RequestException as e:
            return None, f"Erro de conexão com a API: {e}"
        except Exception as e:
            return None, f"Erro inesperado: {e}"

    def handle_send_ai_chat_message(self, e):
        user_text = self.main.ai_chat_input.value.strip()
        if not user_text: return
        if not self.app_state.current_chat_id: self.start_new_chat()

        current_chat = self.app_state.get_current_chat()
        if not current_chat: return

        current_chat["messages"].append({"role": "user", "content": user_text, "type": "text"})
        from views.ai_view import _create_chat_message_control
        cs = self.page.theme.color_scheme if self.page.theme else None
        self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(user_text, "user", cs))
        self.main.ai_chat_input.value = ""
        self.main.ai_chat_loading_indicator.visible = True
        self.main.ai_chat_send_button.disabled = True
        self.page.update()
        persistence.save_state(self.app_state)
        
        system_instruction = prompts.SYSTEM_INSTRUCTION
        data_context = self._format_data_for_ai()
        user_question = prompts.get_chat_user_question_prompt(user_text)
        prompt_parts = [system_instruction, data_context, user_question]
        
        active_file_ctx = self.app_state.active_file_in_chat
        tools_payload = None
        if active_file_ctx and active_file_ctx["chat_id"] == current_chat["id"]:
            filename = os.path.basename(active_file_ctx["file_path"])
            file_content = active_file_ctx["content"]
            file_context_prompt = f"\n\n--- CONTEXTO DE ARQUIVO ANEXADO ATUALMENTE ---\nArquivo: {filename}\nConteúdo:\n{file_content}\n--- FIM DO CONTEXTO DE ARQUIVO ---"
            prompt_parts.insert(2, file_context_prompt)
            if os.path.splitext(filename)[1].lower() in {".xlsx"}:
                tools_payload = self.tools
        
        contents = {"contents": [{"parts": [{"text": "\n\n".join(prompt_parts)}]}]}
        response, error = self.call_gemini_api_sync(contents, tools=tools_payload)

        if isinstance(response, dict):
            self._handle_function_call(response)
            response, error = None, None
        
        self.main.ai_chat_loading_indicator.visible = False
        self.main.ai_chat_send_button.disabled = False
        
        if response:
            ai_content = response
            current_chat["messages"].append({"role": "ai", "content": ai_content, "type": "text"})
            self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "ai", cs))
        elif error:
            ai_content = f"Erro: {error}"
            current_chat["messages"].append({"role": "system", "content": ai_content, "type": "text"})
            self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "system", cs))

        persistence.save_state(self.app_state)
        self.page.update()
        
    def open_chat(self, chat_id: str):
        self.app_state.current_chat_id = chat_id
        self.app_state.active_file_in_chat = None
        persistence.save_state(self.app_state)
        self.page.go(f"/ai/chat/{chat_id}")

    def handle_ai_enabled_change(self, e):
        self.app_state.ai_settings["enabled"] = e.control.value
        persistence.save_state(self.app_state)
        self.main.view.rebuild_drawer()
        self.main.navigation.route_change_handler(ft.RouteChangeEvent(self.page.route))
        self.page.open(ft.SnackBar(ft.Text(f"IA Global {'Habilitada' if e.control.value else 'Desabilitada'}.")))

    def handle_ai_suggestions_change(self, e):
        self.app_state.ai_settings["suggestions_on_dashboard"] = e.control.value
        persistence.save_state(self.app_state)
        self.page.open(ft.SnackBar(ft.Text(f"Sugestões no Dashboard {'Habilitadas' if e.control.value else 'Desabilitadas'}.")))

    def start_new_chat(self, e=None, title: str | None = None, initial_messages: list | None = None):
        new_chat_id = str(uuid.uuid4())
        new_chat = { "id": new_chat_id, "title": title or "Nova Conversa", "timestamp": datetime.now().isoformat(), "messages": initial_messages or [] }
        self.app_state.chat_history.insert(0, new_chat)
        self.app_state.current_chat_id = new_chat_id
        self.app_state.active_file_in_chat = None
        persistence.save_state(self.app_state)
        self.page.go(f"/ai/chat/{new_chat_id}")

    def handle_delete_chat_confirmed(self, chat_id: str):
        was_deleted = self.app_state.delete_chat_by_id(chat_id)
        if was_deleted:
            if self.app_state.current_chat_id == chat_id:
                self.app_state.current_chat_id = None
            persistence.save_state(self.app_state)
            self.page.open(ft.SnackBar(ft.Text("Conversa apagada.")))
        self.page.go("/ai/history")

    def open_rename_dialog(self, e):
        chat_id = e.control.data
        chat = self.app_state.get_chat_by_id(chat_id)
        if not chat: return
        self.main.chat_id_to_rename = chat_id
        self.main.rename_chat_textfield = ft.TextField(label="Novo título da conversa", value=chat.get("title", ""), autofocus=True, on_submit=self.main.confirm_chat_rename, border_color="outline", focused_border_color="primary", cursor_color="primary")
        self.main.rename_chat_dialog = ft.AlertDialog(modal=True, title=ft.Text("Renomear Conversa"), content=self.main.rename_chat_textfield, actions=[ft.TextButton("Cancelar", on_click=self.main.close_rename_dialog), ft.FilledButton("Salvar", on_click=self.main.confirm_chat_rename)], actions_alignment=ft.MainAxisAlignment.END)
        self.page.open(self.main.rename_chat_dialog)

    def confirm_chat_rename(self, e):
        new_title = self.main.rename_chat_textfield.value.strip()
        if new_title:
            self.app_state.update_chat_title(self.main.chat_id_to_rename, new_title)
            persistence.save_state(self.app_state)
            self.close_rename_dialog(e)
            self.page.open(ft.SnackBar(ft.Text("Conversa renomeada com sucesso!")))
            self.main.navigation.route_change_handler(ft.RouteChangeEvent(self.page.route))
        else:
            self.main.rename_chat_textfield.error_text = "O título não pode ser vazio."
            self.main.rename_chat_textfield.update()

    def close_rename_dialog(self, e):
        if self.main.rename_chat_dialog: self.page.close(self.main.rename_chat_dialog)

    def _format_data_for_ai(self, index_name: str | None = None) -> str:
        if not self.app_state.calculated_indices: return ""
        parts = ["## Contexto: Dados Atuais do BoviCheck\n"]
        indices_to_process = {}
        if index_name and index_name in self.app_state.calculated_indices:
            indices_to_process[index_name] = self.app_state.calculated_indices[index_name]
        elif not index_name:
            indices_to_process = self.app_state.calculated_indices
        if not indices_to_process: return ""
        sorted_indices = sorted(indices_to_process.items())
        for name, results in sorted_indices:
            if results:
                parts.append(f"\n### {name}\n")
                try:
                    recent_results = sorted(results, key=lambda x: datetime.strptime(f"{x.get('Data','1/1/1900')} {x.get('Hora','00:00')}", "%d/%m/%Y %H:%M"), reverse=True)[:5]
                except (ValueError, KeyError):
                    recent_results = results[-5:]
                for result in recent_results:
                    parts.append(f"- **{result.get('Resultado', 'N/A')}** (Data: {result.get('Data', 'N/A')})\n")
        return "".join(parts)

    def _handle_suggestion_flow(self, text_control, loading_control, continue_button, prompt_instruction, data_context):
        loading_control.visible = True
        text_control.value = ""
        text_control.opacity = 1.0
        continue_button.visible = False
        self.page.update()
        prompt = f"{prompt_instruction}\n\n{data_context}"
        contents = {"contents": [{"parts": [{"text": prompt}]}]}
        suggestion, error = self.call_gemini_api_sync(contents)
        loading_control.visible = False
        if error:
            text_control.value = f"**Erro ao gerar sugestão:**\n{error}"
        else:
            text_control.value = suggestion
            continue_button.data = suggestion
            continue_button.visible = True
        self.page.update()

    def handle_dashboard_suggestion_click(self, e, text_control, loading_control, continue_button):
        e.control.disabled = True
        data_context = self._format_data_for_ai()
        if not data_context:
            text_control.value = "Não há dados suficientes para gerar uma análise."
            loading_control.visible = False
            e.control.disabled = False
            self.page.update()
            return
        prompt_instruction = prompts.DASHBOARD_SUGGESTION_PROMPT
        self._handle_suggestion_flow(text_control, loading_control, continue_button, prompt_instruction, data_context)
        e.control.disabled = False
        self.page.update()

    def handle_index_suggestion_click(self, e, text_control, loading_control, continue_button):
        e.control.disabled = True
        index_name = e.control.data
        data_context = self._format_data_for_ai(index_name=index_name)
        if not data_context:
            text_control.value = "Não há dados suficientes para gerar uma análise."
            loading_control.visible = False
            e.control.disabled = False
            self.page.update()
            return
        prompt_instruction = prompts.get_index_suggestion_prompt(index_name)
        self._handle_suggestion_flow(text_control, loading_control, continue_button, prompt_instruction, data_context)
        e.control.disabled = False
        self.page.update()

    def handle_continue_in_chat_click(self, e):
        suggestion_text = e.control.data
        if not suggestion_text: return
        title = f"Sobre: {suggestion_text[:35]}..." if len(suggestion_text) > 35 else f"Sobre: {suggestion_text}"
        initial_messages = [{"role": "ai", "content": suggestion_text, "type": "text"}]
        self.start_new_chat(title=title, initial_messages=initial_messages)