import flet as ft

def build_backup_indices_view(controller) -> ft.Container:
    return _build_export_selection_view(
        controller=controller,
        title="Backup de Índices",
        description="Selecione os índices para incluir no arquivo de backup (.json).",
        button_text="Criar Backup dos Índices Selecionados",
        button_icon=ft.Icons.SAVE_ALT_ROUNDED,
        on_button_click=controller.handle_create_backup_click,
        checkbox_dict_ref=controller.backup_checkboxes
    )

def build_export_spreadsheet_view(controller) -> ft.Container:
    return _build_export_selection_view(
        controller=controller,
        title="Exportar Planilha (XLSX)",
        description="Selecione os índices para incluir na planilha XLSX.",
        button_text="Gerar e Salvar Planilha",
        button_icon=ft.Icons.FILE_DOWNLOAD_OUTLINED,
        on_button_click=controller.handle_export_spreadsheet_click,
        checkbox_dict_ref=controller.spreadsheet_checkboxes
    )

def build_export_pdf_view(controller) -> ft.Container:
    return _build_export_selection_view(
        controller=controller,
        title="Exportar Relatório (PDF)",
        description="Selecione os índices para incluir no relatório PDF.",
        button_text="Gerar e Salvar PDF",
        button_icon=ft.Icons.PICTURE_AS_PDF_OUTLINED,
        on_button_click=controller.handle_export_pdf_click,
        checkbox_dict_ref=controller.pdf_checkboxes
    )

def build_restore_indices_view(controller) -> ft.Container:
    return ft.Container(
        content=ft.Column(
            [
                ft.Text("Restaurar Dados de Índices", size=22, weight=ft.FontWeight.BOLD),
                ft.Divider(height=15),
                ft.Text(
                    "Selecione um arquivo de backup (.json). ATENÇÃO: A restauração "
                    "mesclará os dados, adicionando apenas registros que não existem no app atual.",
                    text_align=ft.TextAlign.JUSTIFY
                ),
                ft.Container(height=20),
                ft.FilledButton(
                    "Selecionar Arquivo de Backup",
                    icon=ft.Icons.FOLDER_OPEN_ROUNDED,
                    on_click=controller.handle_select_restore_file_click,
                    style=ft.ButtonStyle(padding=12)
                ),
            ],
            spacing=15,
        ),
        padding=15, expand=True
    )

def _build_export_selection_view(controller, title, description, button_text, button_icon, on_button_click, checkbox_dict_ref) -> ft.Container:
    checkbox_dict_ref.clear()
    checkbox_list = ft.Column(scroll=ft.ScrollMode.ADAPTIVE, spacing=5, expand=True)
    indices_with_data = {name: data for name, data in controller.app_state.calculated_indices.items() if data}

    if not indices_with_data:
        checkbox_list.controls.append(ft.Text("Nenhum dado encontrado para exportar.", italic=True))
    else:
        for name in sorted(indices_with_data.keys()):
            cb = ft.Checkbox(label=name, value=True)
            checkbox_dict_ref[name] = cb
            checkbox_list.controls.append(cb)

    return ft.Container(
        content=ft.Column(
            [
                ft.Text(title, size=22, weight=ft.FontWeight.BOLD),
                ft.Divider(height=10),
                ft.Text(description, text_align=ft.TextAlign.JUSTIFY),
                ft.Container(content=checkbox_list, expand=True, padding=ft.padding.symmetric(vertical=10)),
                ft.FilledButton(button_text, icon=button_icon, on_click=on_button_click, disabled=not indices_with_data),
            ],
            spacing=10, expand=True
        ),
        padding=15, expand=True
    )