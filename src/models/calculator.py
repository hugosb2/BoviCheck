import re
from datetime import datetime
import uuid

class IndexCalculator:
    def __init__(self):
        self.calculation_methods = {
            "Taxa de Prenhez": self._calculate_taxa_prenhez,
            "Taxa de Natalidade": self._calculate_taxa_natalidade,
            "Taxa de Desmame": self._calculate_taxa_desmame,
            "Peso ao Desmame Ajustado P205": self._calculate_peso_ajustado_p205,
            "Ganho Médio Diário (GMD)": self._calculate_gmd,
            "Taxa de Mortalidade": self._calculate_taxa_mortalidade,
            "Idade ao Primeiro Parto": self._calculate_idade_primeiro_parto,
            "Intervalo entre Partos": self._calculate_intervalo_entre_partos,
            "Lotação Animal": self._calculate_lotacao_animal,
            "Produção de Leite por Vaca/Dia": self._calculate_producao_leite,
            "Conversão Alimentar": self._calculate_conversao_alimentar,
            "Rendimento de Carcaça": self._calculate_rendimento_carcaca,
        }

    def _calculate_taxa_prenhez(self, femeas_prenhes, femeas_aptas):
        if femeas_aptas == 0: raise ValueError("Nº de fêmeas aptas não pode ser zero.")
        resultado = (femeas_prenhes / femeas_aptas) * 100
        return resultado, "%"

    def _calculate_taxa_natalidade(self, nascidos_vivos, femeas_aptas):
        if femeas_aptas == 0: raise ValueError("Nº de fêmeas aptas não pode ser zero.")
        resultado = (nascidos_vivos / femeas_aptas) * 100
        return resultado, "%"

    def _calculate_taxa_desmame(self, bezerros_desmamados, bezerros_nascidos):
        if bezerros_nascidos == 0: raise ValueError("Nº de bezerros nascidos não pode ser zero.")
        resultado = (bezerros_desmamados / bezerros_nascidos) * 100
        return resultado, "%"

    def _calculate_peso_ajustado_p205(self, peso_nascer, peso_desmama, idade_desmama):
        if idade_desmama == 0: raise ValueError("Idade ao desmame não pode ser zero.")
        if peso_desmama < peso_nascer: raise ValueError("Peso à desmama menor que peso ao nascer.")
        resultado = peso_nascer + ((peso_desmama - peso_nascer) / idade_desmama) * 205
        return resultado, "kg"

    def _calculate_gmd(self, peso_inicial, peso_final, num_dias):
        if num_dias == 0: raise ValueError("Nº de dias não pode ser zero.")
        resultado = (peso_final - peso_inicial) / num_dias
        return resultado, "kg/dia"

    def _calculate_taxa_mortalidade(self, animais_mortos, total_animais):
        if total_animais == 0: raise ValueError("Nº total de animais não pode ser zero.")
        resultado = (animais_mortos / total_animais) * 100
        return resultado, "%"

    def _calculate_idade_primeiro_parto(self, data_nascimento, data_parto):
        d1 = datetime.strptime(data_nascimento, "%d/%m/%Y")
        d2 = datetime.strptime(data_parto, "%d/%m/%Y")
        if d2 < d1: raise ValueError("Parto não pode ser antes do nascimento.")
        resultado = (d2 - d1).days / 30.4375
        return resultado, "meses"

    def _calculate_intervalo_entre_partos(self, data_parto_anterior, data_parto_atual):
        d1 = datetime.strptime(data_parto_anterior, "%d/%m/%Y")
        d2 = datetime.strptime(data_parto_atual, "%d/%m/%Y")
        if d2 < d1: raise ValueError("Parto atual não pode ser antes do anterior.")
        resultado = (d2 - d1).days
        return resultado, "dias"

    def _calculate_lotacao_animal(self, total_animais, peso_medio, area_pastagem):
        if area_pastagem == 0: raise ValueError("Área de pastagem não pode ser zero.")
        if peso_medio <= 0: raise ValueError("Peso vivo médio deve ser positivo.")
        total_ua = (total_animais * peso_medio) / 450.0
        resultado = total_ua / area_pastagem
        return resultado, "UA/ha"

    def _calculate_producao_leite(self, producao_total, num_vacas):
        if num_vacas == 0: raise ValueError("Nº de vacas em lactação não pode ser zero.")
        resultado = producao_total / num_vacas
        return resultado, "L/vaca/dia"

    def _calculate_conversao_alimentar(self, consumo_ms, ganho_pv):
        if ganho_pv == 0: raise ValueError("Ganho de peso não pode ser zero.")
        resultado = consumo_ms / ganho_pv
        return resultado, "kg MS/kg PV"

    def _calculate_rendimento_carcaca(self, peso_vivo_abate, peso_carcaca):
        if peso_vivo_abate == 0: raise ValueError("Peso vivo antes do abate não pode ser zero.")
        resultado = (peso_carcaca / peso_vivo_abate) * 100
        return resultado, "%"

    def _validar_data(self, data_str: str) -> bool:
        if not re.match(r"^\d{2}/\d{2}/\d{4}$", data_str): return False
        try:
            datetime.strptime(data_str, "%d/%m/%Y")
            return True
        except ValueError: return False

    def _parse_and_validate(self, index_data: dict, values: list) -> list:
        parsed_vals = []
        input_descs = index_data["Inputs"].split(", ")
        is_date_idx = index_data["Índice"] in ["Idade ao Primeiro Parto", "Intervalo entre Partos"]
        
        for i, val_str in enumerate(values):
            desc = input_descs[i] if i < len(input_descs) else f"entrada #{i+1}"
            if is_date_idx and i < 2:
                if not self._validar_data(val_str):
                    raise ValueError(f"Data inválida para '{desc}'. Use DD/MM/AAAA.")
                parsed_vals.append(val_str)
            else:
                try:
                    parsed_float = float(val_str.replace(',', '.'))
                    if parsed_float < 0: raise ValueError()
                    parsed_vals.append(parsed_float)
                except ValueError:
                    raise ValueError(f"O valor para '{desc}' deve ser um número não negativo.")
        return parsed_vals

    def calculate(self, index_data: dict, values: list) -> dict:
        index_name = index_data["Índice"]
        
        calculation_func = self.calculation_methods.get(index_name)
        if not calculation_func:
            raise NotImplementedError(f"Cálculo para '{index_name}' não implementado.")

        parsed_values = self._parse_and_validate(index_data, values)
        
        result_val, unit = calculation_func(*parsed_values)
        
        now = datetime.now()
        return {
            "id": str(uuid.uuid4()),
            "Resultado": f"{result_val:.2f} {unit}",
            "Data": now.strftime("%d/%m/%Y"),
            "Hora": now.strftime("%H:%M"),
            "inputs": values,
        }