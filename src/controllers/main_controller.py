import flet as ft
import os
import requests
import json
from datetime import datetime
import uuid

from models import app_state, persistence, calculator, export_manager, definitions
from views import main_view
from utils import helpers
from . import navigation

class MainController:
    def __init__(self, page: ft.Page):
        self.page = page
        self.app_state = app_state.AppState()

        persistence.load_state(self.app_state)

        self.calculator = calculator.IndexCalculator()
        self.view = main_view.MainView(self)
        self.navigation = navigation.Navigation(self)
        self.ai_chat_messages_list = ft.ListView(expand=True, auto_scroll=True, spacing=10)
        self.ai_chat_input = ft.TextField(
            hint_text="Pergunte algo...",
            expand=True,
            on_submit=self.handle_send_ai_chat_message,
            border_radius=20,
            content_padding=12,
            border_color="outline",
            focused_border_color="primary",
            cursor_color="primary",
        )
        self.ai_chat_loading_indicator = ft.ProgressRing(visible=False, width=20, height=20, stroke_width=2.5)
        self.ai_chat_send_button = ft.IconButton(ft.Icons.SEND_ROUNDED, on_click=self.handle_send_ai_chat_message, tooltip="Enviar")

        self.ai_enabled_switch = ft.Switch(
            label="Habilitar IA (global)",
            on_change=self.handle_ai_enabled_change
        )
        self.ai_dashboard_switch = ft.Switch(
            label="Mostrar sugestões de IA no Dashboard e Índices",
            on_change=self.handle_ai_suggestions_change
        )

        self.indices_search_bar = None
        self.indices_list_view = None
        self.current_input_fields = []
        self.history_details_container = None
        self.backup_checkboxes = {}
        self.spreadsheet_checkboxes = {}
        self.fm_current_path = os.path.expanduser("~") if os.name != 'posix' else "/storage/emulated/0"
        self.fm_path_display = None
        self.fm_directory_listing = None
        self.fm_filename_input = None
        self.fm_initial_filename = ""
        self.fm_save_type = "backup"
        self.data_to_save = None

        self.rename_chat_dialog = None
        self.rename_chat_textfield = None
        self.chat_id_to_rename = None

        self._apply_initial_theme()

    def _apply_initial_theme(self):
        prefs = self.app_state.theme_preference
        self.page.theme_mode = prefs.get("theme_mode", ft.ThemeMode.SYSTEM)
        color_name = prefs.get("primary_color_name", "TEAL_ACCENT_700")
        color_seed = getattr(ft.Colors, color_name, ft.Colors.TEAL_ACCENT_700)

        light_theme = ft.Theme(
            color_scheme_seed=color_seed,
            use_material3=True,
            font_family="OpenSans"
        )
        if light_theme.color_scheme:
            light_theme.color_scheme.background = ft.colors.blend_colors(
                [light_theme.color_scheme.background, color_seed], [0.9, 0.1]
            )
        self.page.theme = light_theme

        dark_theme = ft.Theme(
            color_scheme_seed=color_seed,
            use_material3=True,
            font_family="OpenSans",
            # >>> CORREÇÃO APLICADA AQUI: ft.ThemeVisualDensity -> ft.VisualDensity <<<
            visual_density=ft.VisualDensity.COMPACT,
        )
        if dark_theme.color_scheme:
            dark_theme.color_scheme.primary = color_seed
            dark_theme.color_scheme.background = ft.colors.blend_colors(
                [ft.Colors.BLACK, color_seed], [0.85, 0.15]
            )
            dark_theme.color_scheme.surface = ft.colors.blend_colors(
                [ft.Colors.BLACK, color_seed], [0.8, 0.2]
            )
        self.page.dark_theme = dark_theme


    def go_back(self, e=None):
        if len(self.page.views) > 1:
            self.page.views.pop()
            top_view = self.page.views[-1]
            self.page.go(top_view.route)

    def handle_nav_drawer_change(self, e):
        self.page.drawer.open = False
        routes = ["/dashboard", "/indices", "/ai/history", "/settings/general", "/about"]
        idx = int(e.data)
        if idx < len(routes):
            self.page.go(routes[idx])
        elif idx == 5:
            os._exit(0)
        self.page.update()

    def handle_ai_enabled_change(self, e):
        self.app_state.ai_settings["enabled"] = e.control.value
        persistence.save_state(self.app_state)
        self.view.rebuild_drawer()
        self.navigation.route_change_handler(ft.RouteChangeEvent(self.page.route))
        self.page.open(ft.SnackBar(ft.Text(f"IA Global {'Habilitada' if e.control.value else 'Desabilitada'}.")))

    def handle_ai_suggestions_change(self, e):
        self.app_state.ai_settings["suggestions_on_dashboard"] = e.control.value
        persistence.save_state(self.app_state)
        self.page.open(ft.SnackBar(ft.Text(f"Sugestões no Dashboard {'Habilitadas' if e.control.value else 'Desabilitadas'}.")))

    def get_all_indices(self):
        return definitions.INDICES

    def to_safe_route(self, name: str) -> str:
        return helpers.to_safe_route_param(name)

    def update_indices_list(self, query: str = ""):
        if not self.indices_list_view: return
        from views import indices_list_view

        all_indices = self.get_all_indices()
        query = query.lower().strip()
        filtered = [idx for idx in all_indices if not query or query in idx["Índice"].lower()]

        self.indices_list_view.controls = [indices_list_view.create_index_list_item(self, idx) for idx in filtered]
        if self.indices_list_view.page: self.indices_list_view.update()

    def handle_filter_indices(self, e):
        self.update_indices_list(e.control.value)

    def handle_calculate_click(self, index_data: dict, editing_id: str | None):
        values = [field.value.strip() for field in self.current_input_fields]
        for i, v in enumerate(values):
            if not v: self.current_input_fields[i].error_text = "Campo obrigatório"
            else: self.current_input_fields[i].error_text = None
        if any(f.error_text for f in self.current_input_fields):
            self.page.update(); return

        try:
            result_entry = self.calculator.calculate(index_data, values)
            msg = ""
            if editing_id:
                self.app_state.update_calculation_by_id(index_data["Índice"], editing_id, result_entry)
                msg = f"Índice '{index_data['Índice']}' atualizado!"
            else:
                self.app_state.add_new_calculation(index_data["Índice"], result_entry)
                msg = f"Índice '{index_data['Índice']}' calculado com sucesso!"

            persistence.save_state(self.app_state)
            self.page.open(ft.SnackBar(ft.Text(msg)))
            self.page.go(f"/index/{helpers.to_safe_route_param(index_data['Índice'])}/history")
        except ValueError as e:
            self.page.open(ft.SnackBar(ft.Text(f"Erro de Validação: {e}"), bgcolor=ft.Colors.ERROR_CONTAINER))

    def handle_history_item_selected(self, calc_data: dict, index_name: str):
        if not self.history_details_container: return
        from views.history_view import build_details_card

        details_card = build_details_card(self, calc_data, index_name)
        self.history_details_container.content = details_card
        self.history_details_container.update()

    def handle_theme_mode_change(self, mode: ft.ThemeMode):
        self.page.theme_mode = mode
        self.app_state.theme_preference["theme_mode"] = mode
        persistence.save_state(self.app_state)
        self.page.update()
        self.go_back()

    def handle_theme_color_change(self, color_info: dict):
        self.app_state.theme_preference["primary_color_name"] = color_info["value"]
        self._apply_initial_theme()
        persistence.save_state(self.app_state)
        self.page.update()
        self.go_back()

    def handle_delete_index_confirmed(self, index_name: str):
        if index_name in self.app_state.calculated_indices:
            del self.app_state.calculated_indices[index_name]
            persistence.save_state(self.app_state)
            self.page.open(ft.SnackBar(ft.Text(f"Histórico do índice '{index_name}' foi apagado.")))
        self.page.go("/dashboard")

    def handle_delete_all_data_confirmed(self, e):
        self.app_state.reset()
        persistence.save_state(self.app_state)
        self.page.open(ft.SnackBar(ft.Text("Todos os dados foram apagados.")))
        self.page.go("/dashboard")

    def handle_delete_single_calc_confirmed(self, index_name: str, calc_id: str):
        calc, index = self.app_state.get_calculation_by_id(index_name, calc_id)
        if calc is not None:
            self.app_state.calculated_indices[index_name].pop(index)
            if not self.app_state.calculated_indices[index_name]:
                del self.app_state.calculated_indices[index_name]
            persistence.save_state(self.app_state)
            self.page.open(ft.SnackBar(ft.Text("Medição excluída com sucesso.")))
        self.page.go(f"/index/{helpers.to_safe_route_param(index_name)}/history")

    def handle_create_backup_click(self, e):
        selected_names = [name for name, cb in self.backup_checkboxes.items() if cb.value]
        if not selected_names:
            self.page.open(ft.SnackBar(ft.Text("Nenhum índice selecionado."), bgcolor=ft.Colors.AMBER))
            return

        self.data_to_save = export_manager.backup_to_json_string(self.app_state.calculated_indices, selected_names)
        self.fm_save_type = "backup"
        self.fm_initial_filename = f"bovicheck_backup_{datetime.now().strftime('%Y%m%d')}.json"
        self.page.go("/file_manager/save_data")

    def handle_export_spreadsheet_click(self, e):
        selected_names = [name for name, cb in self.spreadsheet_checkboxes.items() if cb.value]
        if not selected_names:
            self.page.open(ft.SnackBar(ft.Text("Nenhum índice selecionado."), bgcolor=ft.Colors.AMBER))
            return

        excel_bytes = export_manager.generate_spreadsheet_bytes(self.app_state.calculated_indices, selected_names)
        if excel_bytes:
            self.data_to_save = excel_bytes
            self.fm_save_type = "spreadsheet"
            self.fm_initial_filename = f"bovicheck_planilha_{datetime.now().strftime('%Y%m%d')}.xlsx"
            self.page.go("/file_manager/save_data")
        else:
            self.page.open(ft.SnackBar(ft.Text("Erro ao gerar planilha. 'openpyxl' está instalado?"), bgcolor=ft.Colors.ERROR))

    def handle_select_restore_file_click(self, e):
        self.view.restore_file_picker.pick_files(dialog_title="Selecionar Arquivo de Backup (.json)", allow_multiple=False, allowed_extensions=["json"])

    def handle_restore_file_picked(self, e: ft.FilePickerResultEvent):
        if not e.files:
            self.page.open(ft.SnackBar(ft.Text("Restauração cancelada.")))
            return

        try:
            with open(e.files[0].path, "r", encoding='utf-8') as f:
                json_string = f.read()
            success, message, restored_data = export_manager.restore_from_json_string(json_string)

            if success:
                items_added = 0
                for index_name, restored_calcs in restored_data.items():
                    if index_name not in self.app_state.calculated_indices:
                        self.app_state.calculated_indices[index_name] = []
                    existing_ids = {calc.get("id") for calc in self.app_state.calculated_indices[index_name]}
                    for calc_to_restore in restored_calcs:
                        if calc_to_restore.get("id") not in existing_ids:
                            self.app_state.calculated_indices[index_name].append(calc_to_restore)
                            existing_ids.add(calc_to_restore.get("id"))
                            items_added += 1
                persistence.save_state(self.app_state)
                final_message = f"Restauração concluída. {items_added} novo(s) registro(s) adicionado(s)."
                self.page.open(ft.SnackBar(ft.Text(final_message), bgcolor=ft.Colors.GREEN_700))
                self.page.go("/dashboard")
            else:
                self.page.open(ft.SnackBar(ft.Text(message), bgcolor=ft.Colors.ERROR))

        except Exception as ex:
            self.page.open(ft.SnackBar(ft.Text(f"Erro ao ler arquivo: {ex}"), bgcolor=ft.Colors.ERROR))

    def get_fm_display_path(self) -> str:
        max_len = 45
        path = self.fm_current_path
        return ("..." + path[-(max_len-3):]) if len(path) > max_len else path

    def fm_populate_directory_listing(self):
        if not self.fm_directory_listing: return
        self.fm_directory_listing.controls.clear()
        path = self.fm_current_path
        parent = os.path.dirname(path)
        if parent != path:
            self.fm_directory_listing.controls.append(ft.ListTile(leading=ft.Icon(ft.Icons.ARROW_UPWARD, color=ft.Colors.AMBER), title=ft.Text(".. (Voltar)"), on_click=lambda _, p=parent: self.fm_navigate_to_path(p)))
        try:
            for item in sorted(os.listdir(path)):
                full_path = os.path.join(path, item)
                if os.path.isdir(full_path):
                    self.fm_directory_listing.controls.append(ft.ListTile(leading=ft.Icon(ft.Icons.FOLDER), title=ft.Text(item), on_click=lambda _, p=full_path: self.fm_navigate_to_path(p)))
        except Exception as e:
            self.fm_directory_listing.controls.append(ft.Text(f"Erro de acesso: {e}", color=ft.Colors.ERROR))
        if self.fm_directory_listing.page: self.fm_directory_listing.update()

    def fm_navigate_to_path(self, new_path: str):
        self.fm_current_path = os.path.abspath(new_path)
        if self.fm_path_display:
            self.fm_path_display.value = self.get_fm_display_path()
            self.fm_path_display.tooltip = self.fm_current_path
            self.fm_path_display.update()
        self.fm_populate_directory_listing()

    def handle_fm_save_file(self, e):
        filename = self.fm_filename_input.value.strip()
        if not filename:
            self.page.open(ft.SnackBar(ft.Text("Nome do arquivo não pode ser vazio."), bgcolor=ft.Colors.ERROR))
            return

        full_path = os.path.join(self.fm_current_path, filename)
        try:
            mode = "wb" if isinstance(self.data_to_save, bytes) else "w"
            with open(full_path, mode, encoding=None if mode == "wb" else "utf-8") as f:
                f.write(self.data_to_save)
            self.page.open(ft.SnackBar(ft.Text(f"Arquivo salvo com sucesso em: {full_path}"), bgcolor=ft.Colors.GREEN_700))
            self.data_to_save = None
            self.page.go("/dashboard")
        except Exception as ex:
            self.page.open(ft.SnackBar(ft.Text(f"Erro ao salvar arquivo: {ex}"), bgcolor=ft.Colors.ERROR))

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
        self.chat_id_to_rename = chat_id
        self.rename_chat_textfield = ft.TextField(label="Novo título da conversa", value=chat.get("title", ""), autofocus=True, on_submit=self.confirm_chat_rename, border_color="outline", focused_border_color="primary", cursor_color="primary")
        self.rename_chat_dialog = ft.AlertDialog(modal=True, title=ft.Text("Renomear Conversa"), content=self.rename_chat_textfield, actions=[ft.TextButton("Cancelar", on_click=self.close_rename_dialog), ft.FilledButton("Salvar", on_click=self.confirm_chat_rename)], actions_alignment=ft.MainAxisAlignment.END)
        self.page.open(self.rename_chat_dialog)

    def confirm_chat_rename(self, e):
        new_title = self.rename_chat_textfield.value.strip()
        if new_title:
            self.app_state.update_chat_title(self.chat_id_to_rename, new_title)
            persistence.save_state(self.app_state)
            self.close_rename_dialog(e)
            self.page.open(ft.SnackBar(ft.Text("Conversa renomeada com sucesso!")))
            self.navigation.route_change_handler(ft.RouteChangeEvent(self.page.route))
        else:
            self.rename_chat_textfield.error_text = "O título não pode ser vazio."
            self.rename_chat_textfield.update()

    def close_rename_dialog(self, e):
        if self.rename_chat_dialog: self.page.close(self.rename_chat_dialog)

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
        user_text = self.ai_chat_input.value.strip()
        if not user_text: return
        if not self.app_state.current_chat_id: self.start_new_chat()

        current_chat = self.app_state.get_current_chat()
        if not current_chat:
            return

        current_chat["messages"].append({"role": "user", "content": user_text})
        if current_chat.get("title") == "Nova Conversa":
            current_chat["title"] = user_text[:40] + "..." if len(user_text) > 40 else user_text

        from views.ai_view import _create_chat_message_control
        cs = self.page.theme.color_scheme if self.page.theme else None

        self.ai_chat_messages_list.controls.append(_create_chat_message_control(user_text, "user", cs))
        self.ai_chat_input.value = ""
        self.ai_chat_loading_indicator.visible = True
        self.ai_chat_send_button.disabled = True
        self.page.update()

        system_instruction = "Você é um assistente especialista em agropecuária e análise de dados zootécnicos."
        data_context = self._format_data_for_ai()
        user_question = f"Com base no contexto de dados fornecido (se houver), responda à seguinte pergunta do usuário: {user_text}"

        prompt_parts = [system_instruction]
        if data_context: prompt_parts.append(data_context)
        prompt_parts.append(user_question)

        prompt = "\n\n".join(prompt_parts)
        response, error = self.call_gemini_api_sync(prompt)

        self.ai_chat_loading_indicator.visible = False
        self.ai_chat_send_button.disabled = False
        if error:
            ai_content = f"Erro: {error}"
            current_chat["messages"].append({"role": "system", "content": ai_content})
            self.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "system", cs))
        else:
            ai_content = response
            current_chat["messages"].append({"role": "ai", "content": ai_content})
            self.ai_chat_messages_list.controls.append(_create_chat_message_control(ai_content, "ai", cs))

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

        prompt_instruction = "Aja como um consultor agropecuário paciente e didático, falando com um produtor que está começando. Com base no resumo de dados a seguir, forneça uma sugestão clara e simples, explicando o porquê da sugestão de forma fácil de entender. Evite jargões técnicos."
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

        prompt_instruction = f"Aja como um consultor agropecuário paciente, explicando para um produtor leigo. Com base nos dados do índice '{index_name}' a seguir, forneça uma dica prática e fácil de implementar para melhorar este resultado. Explique em termos simples por que essa dica é importante."
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