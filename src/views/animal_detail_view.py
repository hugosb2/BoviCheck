import flet as ft

class FichaView(ft.Column):
    def __init__(self, controller, animal_data, is_new):
        super().__init__()
        self.controller = controller
        self.animal_data = animal_data
        self.is_new = is_new
        self.is_editing = is_new

        self.spacing = 10
        self.scroll = ft.ScrollMode.ADAPTIVE
        self.expand = True

        self.build_content()

    def build_content(self):
        self.controls.clear()
        if self.is_editing:
            self.controls.append(self.build_edit_mode())
        else:
            self.controls.append(self.build_view_mode())

    def toggle_mode(self, e):
        if self.is_new:
            self.controller.page.go("/herd")
            return
            
        self.is_editing = not self.is_editing
        self.build_content()
        self.update()
        
    def build_view_mode(self) -> ft.Column:
        def create_info_tile(icon, title, subtitle):
            return ft.ListTile(
                leading=ft.Icon(icon),
                title=ft.Text(title or "-", weight=ft.FontWeight.BOLD),
                subtitle=ft.Text(subtitle),
                dense=True
            )

        identification_card = ft.Card(
            content=ft.Container(
                content=ft.Column([
                    ft.ListTile(title=ft.Text("Identificação e Dados Básicos", weight=ft.FontWeight.BOLD)),
                    ft.Divider(height=1),
                    create_info_tile(ft.Icons.TAG, self.animal_data.get("brinco_interno"), "Brinco Interno/Manejo"),
                    create_info_tile(ft.Icons.LABEL_OUTLINE, self.animal_data.get("nome"), "Nome do Animal"),
                    create_info_tile(ft.Icons.CAKE_OUTLINED, self.animal_data.get("data_nascimento"), "Data de Nascimento"),
                    create_info_tile(ft.Icons.DNS_OUTLINED, self.animal_data.get("raca"), "Raça"),
                    create_info_tile(ft.Icons.WC_OUTLINED, self.animal_data.get("sexo"), "Sexo"),
                    create_info_tile(ft.Icons.LOCATION_ON_OUTLINED, self.animal_data.get("lote_atual"), "Lote Atual"),
                    create_info_tile(ft.Icons.CHECK_CIRCLE_OUTLINE, self.animal_data.get("status_animal"), "Status"),
                ]), padding=ft.padding.symmetric(vertical=10)
            )
        )
        
        filiation_card = ft.Card(
            content=ft.Container(
                content=ft.Column([
                    ft.ListTile(title=ft.Text("Filiação", weight=ft.FontWeight.BOLD)),
                    ft.Divider(height=1),
                    create_info_tile(ft.Icons.FEMALE, self.animal_data.get("id_mae"), "Brinco da Mãe"),
                    create_info_tile(ft.Icons.MALE, self.animal_data.get("id_pai"), "Brinco/ID do Pai"),
                ]), padding=ft.padding.symmetric(vertical=10)
            )
        )

        return ft.Column(
            controls=[
                ft.Row(
                    [ft.FilledButton("Editar Ficha", icon=ft.Icons.EDIT_OUTLINED, on_click=self.toggle_mode)],
                    alignment=ft.MainAxisAlignment.END
                ),
                identification_card,
                filiation_card,
            ],
            spacing=10
        )

    def build_edit_mode(self) -> ft.Column:
        animal_controller = self.controller.animal_controller
        animal_id = self.animal_data.get("id")
        
        form_fields = {}

        def create_field(key, label, value, **kwargs):
            field = ft.TextField(label=label, value=str(value or ""), border_color="outline", cursor_color="primary", **kwargs)
            form_fields[key] = field
            return field

        def create_dropdown(key, label, value, options):
            dd = ft.Dropdown(
                label=label, value=value, options=[ft.dropdown.Option(opt) for opt in options], border_color="outline",
            )
            form_fields[key] = dd
            return dd

        form_fields['brinco_interno'] = create_field("brinco_interno", "Brinco Interno/Manejo*", self.animal_data.get("brinco_interno"))
        form_fields['nome'] = create_field("nome", "Nome do Animal", self.animal_data.get("nome"))
        form_fields['data_nascimento'] = create_field("data_nascimento", "Data de Nascimento (DD/MM/AAAA)", self.animal_data.get("data_nascimento"))
        form_fields['raca'] = create_field("raca", "Raça", self.animal_data.get("raca"))
        form_fields['sexo'] = create_dropdown("sexo", "Sexo", self.animal_data.get("sexo"), ["Fêmea", "Macho"])
        form_fields['lote_atual'] = create_field("lote_atual", "Lote Atual", self.animal_data.get("lote_atual"))
        form_fields['status_animal'] = create_dropdown("status_animal", "Status", self.animal_data.get("status_animal"), ["Ativo", "Vendido", "Morto", "Descarte"])
        form_fields['id_mae'] = create_field("id_mae", "Brinco da Mãe", self.animal_data.get("id_mae"))
        form_fields['id_pai'] = create_field("id_pai", "Brinco/ID do Pai", self.animal_data.get("id_pai"))
        
        animal_controller.animal_form_fields = form_fields

        identification_card = ft.Card(
            content=ft.Container(
                content=ft.Column([
                    ft.Text("Identificação e Dados Básicos", weight=ft.FontWeight.BOLD),
                    form_fields['brinco_interno'], form_fields['nome'], form_fields['data_nascimento'],
                    form_fields['raca'], form_fields['sexo'], form_fields['lote_atual'], form_fields['status_animal'],
                ]), padding=15
            ), elevation=1.5
        )

        filiation_card = ft.Card(
            content=ft.Container(
                content=ft.Column([
                    ft.Text("Filiação", weight=ft.FontWeight.BOLD),
                    form_fields['id_mae'], form_fields['id_pai'],
                ]), padding=15
            ), elevation=1.5
        )

        save_button = ft.FilledButton("Salvar Ficha", icon=ft.Icons.SAVE_OUTLINED, on_click=lambda e: animal_controller.handle_save_animal(animal_id))
        cancel_button = ft.TextButton("Cancelar", on_click=self.toggle_mode)
        
        return ft.Column(
            controls=[
                identification_card, filiation_card,
                ft.Row([cancel_button, save_button], alignment=ft.MainAxisAlignment.END)
            ], spacing=10
        )

class AnimalDetailView(ft.Column):
    def __init__(self, controller, animal_data):
        super().__init__()
        self.controller = controller
        self.animal_data = animal_data
        self.content_area = ft.Container(expand=True)
        
        self.expand = True
        self.spacing = 0

        self.navigation_bar = ft.NavigationBar(
            selected_index=0,
            on_change=self.switch_content,
            destinations=[
                ft.NavigationBarDestination(icon=ft.Icons.DESCRIPTION_OUTLINED, selected_icon=ft.Icons.DESCRIPTION, label="Ficha"),
                ft.NavigationBarDestination(icon=ft.Icons.SCALE_OUTLINED, selected_icon=ft.Icons.SCALE, label="Pesagens"),
                ft.NavigationBarDestination(icon=ft.Icons.VACCINES_OUTLINED, selected_icon=ft.Icons.VACCINES, label="Vacinas"),
                ft.NavigationBarDestination(icon=ft.Icons.MEDICAL_SERVICES_OUTLINED, selected_icon=ft.Icons.MEDICAL_SERVICES, label="Ocorrências"),
            ]
        )
        
        self.controls = [self.content_area, self.navigation_bar]
        self.update_content(0)

    def switch_content(self, e):
        self.update_content(e.control.selected_index)

    def update_content(self, selected_index: int):
        if selected_index == 0:
            self.content_area.content = _build_ficha_content(self.controller, self.animal_data)
        elif selected_index == 1:
            self.content_area.content = _build_pesagens_content(self.controller, self.animal_data)
        elif selected_index == 2:
            self.content_area.content = _build_vacinas_section(self.controller, self.animal_data)
        elif selected_index == 3:
            self.content_area.content = _build_doencas_section(self.controller, self.animal_data)
        
        if self.page:
            self.update()

def build_animal_detail_view(controller, animal_id: str | None) -> ft.Container:
    is_new_animal = animal_id is None
    if is_new_animal:
        return _build_ficha_content(controller, None)
    
    animal_data, _ = controller.app_state.get_animal_by_id(animal_id)
    if not animal_data:
        return ft.Container(content=ft.Text(f"Erro: Animal com ID '{animal_id}' não encontrado."))

    return AnimalDetailView(controller, animal_data)

def _build_ficha_content(controller, animal_data: dict | None) -> ft.Container:
    is_new = animal_data is None
    if is_new:
        animal_data = controller.animal_controller.get_new_animal_template()
    return ft.Container(content=FichaView(controller, animal_data, is_new), padding=10, expand=True)

def _create_history_item_menu(controller, animal_id, history_key, record_id):
    return ft.PopupMenuButton(
        icon=ft.Icons.MORE_VERT,
        items=[
            ft.PopupMenuItem(
                text="Editar", icon=ft.Icons.EDIT_OUTLINED,
                on_click=lambda _: controller.page.go(f"/animal/{animal_id}/edit/{history_key}/{record_id}")
            ),
            ft.PopupMenuItem(
                text="Excluir", icon=ft.Icons.DELETE_OUTLINE,
                on_click=lambda _: controller.page.go(f"/animal/{animal_id}/delete_history/{history_key}/{record_id}")
            ),
        ]
    )

def _build_pesagens_content(controller, animal_data: dict) -> ft.Container:
    history = animal_data.get("historico_pesagens", [])
    
    pesagens_list_controls = []
    if not history:
        pesagens_list_controls.append(ft.Text("Nenhum registro de peso encontrado.", italic=True, opacity=0.8))
    else:
        for item in history:
            card = ft.Card(
                content=ft.ListTile(
                    leading=ft.Icon(ft.Icons.SCALE_OUTLINED, color="primary"),
                    title=ft.Text(f"{item.get('peso', 'N/A')} kg", weight=ft.FontWeight.BOLD),
                    subtitle=ft.Text(f"Data: {item.get('data', 'N/A')}"),
                    trailing=_create_history_item_menu(controller, animal_data["id"], "historico_pesagens", item["id"]),
                ),
                elevation=1.5
            )
            pesagens_list_controls.append(card)

    column = ft.Column(
        controls=[
            ft.Row([
                ft.Text("Histórico de Pesos", size=18, weight=ft.FontWeight.BOLD, expand=True),
                ft.FilledButton("Registrar Pesagem", icon=ft.Icons.ADD, on_click=lambda _: controller.page.go(f"/animal/{animal_data['id']}/add/historico_pesagens"))
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            ft.Divider(),
            ft.Column(controls=pesagens_list_controls, spacing=8, scroll=ft.ScrollMode.ADAPTIVE, expand=True)
        ],
        spacing=12,
        expand=True,
    )
    
    return ft.Container(content=column, padding=15, expand=True)

def _build_vacinas_section(controller, animal_data: dict) -> ft.Container:
    vacinas = animal_data.get("historico_vacinacao", [])
    vacinas_list_controls = []
    if not vacinas:
        vacinas_list_controls.append(ft.Text("Nenhum registro de vacina encontrado.", italic=True, opacity=0.8))
    else:
        for item in vacinas:
            card = ft.Card(
                content=ft.ListTile(
                    leading=ft.Icon(ft.Icons.VACCINES_OUTLINED, color="primary"),
                    title=ft.Text(item.get("vacina", "N/A"), weight=ft.FontWeight.BOLD),
                    subtitle=ft.Text(f"Data: {item.get('data', 'N/A')} • Dose: {item.get('dose', 'N/A')}"),
                    trailing=_create_history_item_menu(controller, animal_data["id"], "historico_vacinacao", item["id"]),
                ),
                elevation=1.5
            )
            vacinas_list_controls.append(card)
    
    column = ft.Column(
        controls=[
            ft.Row([
                ft.Text("Vacinação e Vermifugação", size=18, weight=ft.FontWeight.BOLD, expand=True),
                ft.FilledButton("Registrar Aplicação", icon=ft.Icons.ADD, on_click=lambda _: controller.page.go(f"/animal/{animal_data['id']}/add/historico_vacinacao"))
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            ft.Divider(),
            ft.Column(controls=vacinas_list_controls, spacing=8, scroll=ft.ScrollMode.ADAPTIVE, expand=True),
        ],
        spacing=12,
        expand=True,
    )
    return ft.Container(content=column, padding=15, expand=True)

def _build_doencas_section(controller, animal_data: dict) -> ft.Container:
    doencas = animal_data.get("historico_doencas", [])
    doencas_list_controls = []
    if not doencas:
        doencas_list_controls.append(ft.Text("Nenhuma ocorrência de saúde registrada.", italic=True, opacity=0.8))
    else:
        for item in doencas:
            card = ft.Card(
                content=ft.ListTile(
                    leading=ft.Icon(ft.Icons.MEDICAL_SERVICES_OUTLINED, color="orange"),
                    title=ft.Text(item.get("doenca", "N/A"), weight=ft.FontWeight.BOLD),
                    subtitle=ft.Text(f"Data: {item.get('data', 'N/A')} • Tratamento: {item.get('tratamento', 'N/A')}"),
                    trailing=_create_history_item_menu(controller, animal_data["id"], "historico_doencas", item["id"]),
                ),
                elevation=1.5
            )
            doencas_list_controls.append(card)

    column = ft.Column(
        controls=[
            ft.Row([
                ft.Text("Ocorrências de Saúde", size=18, weight=ft.FontWeight.BOLD, expand=True),
                ft.FilledButton("Registrar Ocorrência", icon=ft.Icons.ADD, on_click=lambda _: controller.page.go(f"/animal/{animal_data['id']}/add/historico_doencas"))
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            ft.Divider(),
            ft.Column(controls=doencas_list_controls, spacing=8, scroll=ft.ScrollMode.ADAPTIVE, expand=True),
        ],
        spacing=12,
        expand=True,
    )
    return ft.Container(content=column, padding=15, expand=True)