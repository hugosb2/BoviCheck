import flet as ft
import os
import math

def _format_file_size(size_bytes):
    if size_bytes <= 0:
        return "0B"
    size_name = ("B", "KB", "MB", "GB", "TB")
    i = int(math.floor(math.log(size_bytes, 1024)))
    p = math.pow(1024, i)
    s = round(size_bytes / p, 2)
    return f"{s} {size_name[i]}"

def build_ai_chat_view(controller, chat_id: str) -> ft.Container:
    chat_file_picker = ft.FilePicker(on_result=lambda e: handle_file_picked(e, controller))
    if chat_file_picker not in controller.page.overlay:
        controller.page.overlay.append(chat_file_picker)

    _create_chat_message_control.page = controller.page
    
    controller.app_state.current_chat_id = chat_id
    current_chat = controller.app_state.get_current_chat()
    
    cs = controller.page.theme.color_scheme if controller.page.theme else None
    controller.ai_chat_messages_list.controls.clear()

    if not controller.app_state.ai_settings.get("enabled", False):
        msg = "A funcionalidade de IA está desabilitada. Ative-a em Configurações."
        controller.ai_chat_messages_list.controls.append(_create_chat_message_control(msg, "system", cs))
    elif current_chat and current_chat.get('messages'):
        for message in current_chat['messages']:
            content = message.get("content", "")
            role = message.get("role", "system")
            caption = message.get("caption", "")
            if message.get("type") == "image":
                controller.ai_chat_messages_list.controls.append(
                    _create_image_message_control(content, caption, role, cs)
                )
            elif message.get("type") == "file":
                controller.ai_chat_messages_list.controls.append(
                    _create_file_message_control(content, role, cs)
                )
            else:
                controller.ai_chat_messages_list.controls.append(
                    _create_chat_message_control(content, role, cs)
                )
    else:
        msg = "Olá! Como posso ajudar com seus dados agropecuários hoje?"
        controller.ai_chat_messages_list.controls.append(_create_chat_message_control(msg, "ai", cs))

    chat_column = ft.Column([
            ft.Container(
                content=controller.ai_chat_messages_list, 
                expand=True, 
                border=ft.border.all(1, ft.Colors.with_opacity(0.2, ft.Colors.OUTLINE)), 
                border_radius=8
            ),
            ft.Row([
                ft.IconButton(
                    icon=ft.Icons.ATTACH_FILE_ROUNDED,
                    tooltip="Anexar arquivo",
                    on_click=lambda _: chat_file_picker.pick_files(
                        allow_multiple=False,
                        allowed_extensions=["png", "jpg", "jpeg", "pdf", "txt", "docx", "xlsx", "csv"]
                    )
                ),
                controller.ai_chat_input, 
                controller.ai_chat_loading_indicator, 
                controller.ai_chat_send_button
            ], vertical_alignment=ft.CrossAxisAlignment.CENTER)
        ], spacing=10, expand=True
    )
    return ft.Container(content=chat_column, padding=15, expand=True)

def handle_file_picked(e: ft.FilePickerResultEvent, controller):
    if not e.files:
        return
    file_path = e.files[0].path
    if file_path:
        open_caption_dialog(file_path, controller)

def open_caption_dialog(file_path: str, controller):
    caption_textfield = ft.TextField(
        label="Legenda ou pergunta sobre o arquivo (opcional)",
        autofocus=True,
        shift_enter=True,
        min_lines=1,
        max_lines=3,
    )

    image_extensions = {".png", ".jpg", ".jpeg"}
    file_ext = os.path.splitext(file_path)[1].lower()
    
    if file_ext in image_extensions:
        preview_widget = ft.Image(src=file_path, height=150, fit=ft.ImageFit.CONTAIN, border_radius=8)
    else:
        filename = os.path.basename(file_path)
        preview_widget = ft.ListTile(
            leading=ft.Icon(ft.Icons.INSERT_DRIVE_FILE_OUTLINED, size=40),
            title=ft.Text(filename, weight=ft.FontWeight.BOLD),
            subtitle=ft.Text("Arquivo a ser enviado")
        )

    def close_dialog(e):
        dialog.open = False
        controller.page.update()

    def send_with_caption(e):
        caption = caption_textfield.value or ""
        controller.ai_controller.handle_file_submission(file_path, caption)
        close_dialog(e)

    dialog = ft.AlertDialog(
        modal=True,
        title=ft.Text("Anexar Arquivo"),
        content=ft.Column([preview_widget, caption_textfield], tight=True, spacing=15),
        actions=[
            ft.TextButton("Cancelar", on_click=close_dialog),
            ft.FilledButton("Enviar Anexo", on_click=send_with_caption),
        ],
        actions_alignment=ft.MainAxisAlignment.END,
    )

    controller.page.open(dialog)

def _create_chat_message_control(text: str, role: str, cs) -> ft.Row:
    is_user = role == "user"
    
    message_widget = ft.Markdown(
        value=text,
        selectable=True,
        extension_set=ft.MarkdownExtensionSet.GITHUB_WEB
    )
    
    if is_user:
        bubble_bgcolor = ft.Colors.with_opacity(0.05, ft.Colors.ON_SURFACE)
    else:
        bubble_bgcolor = ft.Colors.with_opacity(0.03, ft.Colors.PRIMARY_CONTAINER)

    message_bubble = ft.Container(
        content=message_widget,
        bgcolor=bubble_bgcolor,
        padding=ft.padding.symmetric(horizontal=12, vertical=10),
        border_radius=12,
        margin=ft.margin.symmetric(vertical=4),
    )

    if is_user:
        controls = [ft.Container(expand=1), ft.Container(content=message_bubble, expand=4)]
    else:
        controls = [ft.Container(content=message_bubble, expand=4), ft.Container(expand=1)]
    
    return ft.Row(controls)

def _create_image_message_control(file_path: str, caption: str, role: str, cs) -> ft.Row:
    is_user = role == "user"
    
    image_content = [
        ft.Image(
            src=file_path,
            border_radius=ft.border_radius.only(top_left=12, top_right=12),
            width=260,
            fit=ft.ImageFit.CONTAIN
        )
    ]
    if caption:
        image_content.append(
            ft.Container(
                content=ft.Text(caption, selectable=True, size=13),
                padding=ft.padding.symmetric(horizontal=10, vertical=8),
            )
        )
        
    image_container = ft.Container(
        content=ft.Column(image_content, spacing=0),
        border=ft.border.all(1, ft.Colors.with_opacity(0.2, "outline")),
        border_radius=12,
        clip_behavior=ft.ClipBehavior.HARD_EDGE,
    )
    
    if is_user:
        controls = [ft.Container(expand=1), ft.Container(content=image_container)]
    else:
        controls = [ft.Container(content=image_container), ft.Container(expand=1)]
    
    return ft.Row(controls, alignment=ft.MainAxisAlignment.END if is_user else ft.MainAxisAlignment.START)

def _create_file_message_control(file_path: str, role: str, cs) -> ft.Row:
    is_user = role == "user"
    filename = os.path.basename(file_path)
    
    try:
        size_in_bytes = os.path.getsize(file_path)
        filesize_str = _format_file_size(size_in_bytes)
    except OSError:
        filesize_str = "Tamanho desconhecido"

    file_card = ft.Card(
        content=ft.Container(
            content=ft.ListTile(
                leading=ft.Icon(ft.Icons.INSERT_DRIVE_FILE_OUTLINED, size=30),
                title=ft.Text(filename, weight=ft.FontWeight.BOLD, size=14, no_wrap=True),
                subtitle=ft.Text(f"Arquivo anexado - {filesize_str}", size=12),
            ),
            padding=ft.padding.symmetric(vertical=5, horizontal=10)
        ),
        elevation=1.5,
        width=280
    )

    if is_user:
        controls = [ft.Container(expand=1), file_card]
    else:
        controls = [file_card, ft.Container(expand=1)]
    
    return ft.Row(controls, alignment=ft.MainAxisAlignment.END if is_user else ft.MainAxisAlignment.START)

def _create_confirmation_control(text: str, on_confirm, on_cancel) -> ft.Card:
    def handle_click(e, original_handler):
        for control in e.control.parent.controls:
            control.disabled = True
        e.control.page.update()
        original_handler(e)

    confirmation_card = ft.Card(
        content=ft.Container(
            content=ft.Column([
                ft.Row(
                    [
                        ft.Icon(ft.Icons.HELP_OUTLINE_ROUNDED, color=ft.Colors.AMBER, size=28),
                        ft.Column(
                            [
                                ft.Text(text, weight=ft.FontWeight.BOLD, no_wrap=False),
                                ft.Text("Aguardando sua aprovação para continuar.", opacity=0.8, size=12),
                            ],
                            spacing=4,
                            expand=True,
                        ),
                    ],
                    spacing=15,
                    vertical_alignment=ft.CrossAxisAlignment.START,
                ),
                ft.Row(
                    [
                        ft.TextButton("Cancelar", on_click=lambda e: handle_click(e, on_cancel), style=ft.ButtonStyle(color=ft.Colors.ERROR)),
                        ft.FilledButton("Confirmar", on_click=lambda e: handle_click(e, on_confirm)),
                    ],
                    alignment=ft.MainAxisAlignment.END,
                )
            ]),
            padding=ft.padding.all(15)
        )
    )
    
    return confirmation_card

def build_ai_settings_view(controller) -> ft.Container:
    state = controller.app_state
    
    controller.ai_enabled_switch.value = state.ai_settings.get("enabled", False)
    controller.ai_dashboard_switch.value = state.ai_settings.get("suggestions_on_dashboard", True)
    
    settings_column = ft.Column([
            ft.Text("Configurações de IA", size=22, weight=ft.FontWeight.BOLD),
            ft.Divider(height=15),
            controller.ai_enabled_switch,
            ft.Text("Permite que a IA forneça sugestões e participe do chat.", size=12),
            ft.Container(height=10),
            controller.ai_dashboard_switch,
            ft.Text("Controla a visibilidade dos cards de IA no Dashboard e nos Índices.", size=12),
        ], spacing=10,
    )
    return ft.Container(content=settings_column, padding=20, expand=True)