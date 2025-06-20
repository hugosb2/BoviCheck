import re
from datetime import datetime
import uuid

class IndexCalculator:
    def _validar_data(self, data_str: str) -> bool:
        if not re.match(r"^\d{2}/\d{2}/\d{4}$", data_str): return False
        try:
            datetime.strptime(data_str, "%d/%m/%Y")
            return True
        except ValueError: return False

    def _parse_and_validate(self, index_data: dict, values: list) -> list:
        p_vals, descs = [], index_data["Inputs"].split(", ")
        is_date_idx = index_data["Índice"] in ["Idade ao Primeiro Parto", "Intervalo entre Partos"]
        for i, val_str in enumerate(values):
            desc = descs[i] if i < len(descs) else f"entrada #{i+1}"
            if is_date_idx and i < 2:
                if not self._validar_data(val_str):
                    raise ValueError(f"Data inválida para '{desc}'. Use DD/MM/AAAA.")
                p_vals.append(val_str)
            else:
                try:
                    parsed = float(val_str.replace(',', '.'))
                    if parsed < 0: raise ValueError()
                    p_vals.append(parsed)
                except ValueError:
                    raise ValueError(f"Valor para '{desc}' deve ser um número não negativo.")
        return p_vals

    def calculate(self, index_data: dict, values: list) -> dict:
        p = self._parse_and_validate(index_data, values)
        name, res, unit = index_data["Índice"], 0.0, ""

        if name == "Taxa de Prenhez":
            if p[1] == 0: raise ValueError("Nº de fêmeas aptas não pode ser zero.")
            res, unit = (p[0] / p[1]) * 100, "%"
        elif name == "Taxa de Natalidade":
            if p[1] == 0: raise ValueError("Nº de fêmeas aptas não pode ser zero.")
            res, unit = (p[0] / p[1]) * 100, "%"
        elif name == "Taxa de Desmame":
            if p[1] == 0: raise ValueError("Nº de bezerros nascidos não pode ser zero.")
            res, unit = (p[0] / p[1]) * 100, "%"
        elif name == "Peso ao Desmame Ajustado P205":
            if p[2] == 0: raise ValueError("Idade ao desmame não pode ser zero.")
            if p[1] < p[0]: raise ValueError("Peso à desmama menor que peso ao nascer.")
            res, unit = p[0] + ((p[1] - p[0]) / p[2]) * 205, "kg"
        elif name == "Ganho Médio Diário (GMD)":
            if p[2] == 0: raise ValueError("Nº de dias não pode ser zero.")
            res, unit = (p[1] - p[0]) / p[2], "kg/dia"
        elif name == "Taxa de Mortalidade":
            if p[1] == 0: raise ValueError("Nº total de animais não pode ser zero.")
            res, unit = (p[0] / p[1]) * 100, "%"
        elif name == "Idade ao Primeiro Parto":
            d1, d2 = datetime.strptime(p[0], "%d/%m/%Y"), datetime.strptime(p[1], "%d/%m/%Y")
            if d2 < d1: raise ValueError("Parto não pode ser antes do nascimento.")
            res, unit = (d2 - d1).days / 30.4375, "meses"
        elif name == "Intervalo entre Partos":
            d1, d2 = datetime.strptime(p[0], "%d/%m/%Y"), datetime.strptime(p[1], "%d/%m/%Y")
            if d2 < d1: raise ValueError("Parto atual não pode ser antes do anterior.")
            res, unit = (d2 - d1).days, "dias"
        elif name == "Lotação Animal":
            if p[2] == 0: raise ValueError("Área de pastagem não pode ser zero.")
            if p[1] <= 0: raise ValueError("Peso vivo médio deve ser positivo.")
            total_ua = (p[0] * p[1]) / 450.0
            res, unit = total_ua / p[2], "UA/ha"
        elif name == "Produção de Leite por Vaca/Dia":
            if p[1] == 0: raise ValueError("Nº de vacas em lactação não pode ser zero.")
            res, unit = p[0] / p[1], "L/vaca/dia"
        elif name == "Conversão Alimentar":
            if p[1] == 0: raise ValueError("Ganho de peso não pode ser zero.")
            res, unit = p[0] / p[1], "kg MS/kg PV"
        elif name == "Rendimento de Carcaça":
            if p[0] == 0: raise ValueError("Peso vivo antes do abate não pode ser zero.")
            res, unit = (p[1] / p[0]) * 100, "%"
        else:
            raise ValueError(f"Cálculo para '{name}' não implementado.")
        
        now = datetime.now()
        return {
            "id": str(uuid.uuid4()),
            "Resultado": f"{res:.2f} {unit}", 
            "Data": now.strftime("%d/%m/%Y"),
            "Hora": now.strftime("%H:%M"), 
            "inputs": values,
        }