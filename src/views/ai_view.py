import flet as ft

def build_ai_chat_view(controller, chat_id: str) -> ft.Container:
    _create_chat_message_control.page = controller.page
    
    controller.app_state.current_chat_id = chat_id
    current_chat = controller.app_state.get_current_chat()
    
    cs = controller.page.theme.color_scheme if controller.page.theme else None
    controller.ai_chat_messages_list.controls.clear()

    if not controller.app_state.ai_settings.get("enabled", False):
        msg = "A funcionalidade de IA está desabilitada. Ative-a em Configurações."
        controller.ai_chat_messages_list.controls.append(_create_chat_message_control(msg, "system", cs))
    elif current_chat and current_chat['messages']:
        for message in current_chat['messages']:
            controller.ai_chat_messages_list.controls.append(
                _create_chat_message_control(message['content'], message['role'], cs)
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
                controller.ai_chat_input, 
                controller.ai_chat_loading_indicator, 
                controller.ai_chat_send_button
            ], vertical_alignment=ft.CrossAxisAlignment.CENTER)
        ], spacing=10, expand=True
    )
    return ft.Container(content=chat_column, padding=15, expand=True)

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
        controls = [
            ft.Container(expand=1),
            ft.Container(content=message_bubble, expand=4)
        ]
    else:
        controls = [
            ft.Container(content=message_bubble, expand=4),
            ft.Container(expand=1)
        ]
    
    return ft.Row(controls)

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