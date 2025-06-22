import flet as ft
import requests
import uuid
from datetime import datetime
from models import persistence, prompts

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
        persistence.save_state(self.app_state)
        self.page.go(f"/ai/chat/{new_chat_id}")

    def open_chat(self, chat_id: str):
        self.app_state.current_chat_id = chat_id
        persistence.save_state(self.app_state)
        self.page.go(f"/ai/chat/{chat_id}")

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

    def handle_send_ai_chat_message(self, e):
        user_text = self.main.ai_chat_input.value.strip()
        if not user_text: return
        if not self.app_state.current_chat_id: self.start_new_chat()

        current_chat = self.app_state.get_current_chat()
        if not current_chat: return

        current_chat["messages"].append({"role": "user", "content": user_text})
        if current_chat.get("title") == "Nova Conversa":
            current_chat["title"] = user_text[:40] + "..." if len(user_text) > 40 else user_text

        from views.ai_view import _create_chat_message_control
        cs = self.page.theme.color_scheme if self.page.theme else None

        self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(user_text, "user", cs))
        self.main.ai_chat_input.value = ""
        self.main.ai_chat_loading_indicator.visible = True
        self.main.ai_chat_send_button.disabled = True
        self.page.update()

        system_instruction = prompts.SYSTEM_INSTRUCTION
        data_context = self._format_data_for_ai()
        user_question = prompts.get_chat_user_question_prompt(user_text)
        
        prompt_parts = [system_instruction]
        if data_context: prompt_parts.append(data_context)
        prompt_parts.append(user_question)
        
        prompt = "\n\n".join(prompt_parts)
        response, error = self.call_gemini_api_sync(prompt)

        self.main.ai_chat_loading_indicator.visible = False
        self.main.ai_chat_send_button.disabled = False
        if error:
            ai_content = f"Erro: {error}"
            current_chat["messages"].append({"role": "system", "content": ai_content})
            self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "system", cs))
        else:
            ai_content = response
            current_chat["messages"].append({"role": "ai", "content": ai_content})
            self.main.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "ai", cs))

        persistence.save_state(self.app_state)
        self.page.update()

    def _handle_suggestion_flow(self, text_control, loading_control, continue_button, prompt_instruction, data_context):
        loading_control.visible = True
        text_control.value = ""
        text_control.opacity = 1.0
        continue_button.visible = False
        self.page.update()
        prompt = f"{prompt_instruction}\n\n{data_context}"
        suggestion, error = self.call_gemini_api_sync(prompt)
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
        initial_messages = [{"role": "ai", "content": suggestion_text}]
        self.start_new_chat(title=title, initial_messages=initial_messages)

    def call_gemini_api_sync(self, prompt_text: str) -> tuple[str | None, str | None]:
        api_key = self.app_state.ai_settings.get("api_key")
        if not self.app_state.ai_settings.get("enabled") or not api_key:
            return None, "A funcionalidade de IA está desabilitada ou a chave de API não foi configurada."

        api_url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key={api_key}"
        headers = {'Content-Type': 'application/json'}
        payload = {"contents": [{"parts": [{"text": prompt_text}]}]}

        try:
            response = requests.post(api_url, json=payload, headers=headers, timeout=45)
            response.raise_for_status()
            result = response.json()
            if "candidates" in result and result["candidates"]:
                content = result["candidates"][0].get("content", {})
                if content.get("parts"):
                    return content["parts"][0].get("text", "").strip(), None

            error_info = result.get('error', {})
            return None, f"Resposta inválida da API: {error_info.get('message', 'Formato desconhecido')}"
        except requests.exceptions.HTTPError as http_err:
            return None, f"Erro HTTP: {http_err}. Verifique sua chave de API e permissões."
        except requests.exceptions.RequestException as e:
            return None, f"Erro de conexão com a API: {e}"
        except Exception as e:
            return None, f"Erro inesperado: {e}"