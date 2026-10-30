class MetasModel {
  double pesoAtual;
  double metaPeso;

  double cinturaAntes;
  double cinturaDepois;

  double quadrilAntes;
  double quadrilDepois;

  double coxaAntes;
  double coxaDepois;

  double bracoAntes;
  double bracoDepois;

  MetasModel({
    this.pesoAtual = 79.2,
    this.metaPeso = 75.0,
    this.cinturaAntes = 92.0,
    this.cinturaDepois = 86.0,
    this.quadrilAntes = 108.0,
    this.quadrilDepois = 102.0,
    this.coxaAntes = 62.0,
    this.coxaDepois = 59.0,
    this.bracoAntes = 32.0,
    this.bracoDepois = 31.0,
  });

  factory MetasModel.fromJson(Map<String, dynamic> json) {
    return MetasModel(
      pesoAtual: double.tryParse(json['peso_atual']?.toString() ?? '') ?? 79.2,
      metaPeso: double.tryParse(json['meta_peso']?.toString() ?? '') ?? 75.0,
      cinturaAntes: double.tryParse(json['cintura_antes']?.toString() ?? '') ?? 92.0,
      cinturaDepois: double.tryParse(json['cintura_depois']?.toString() ?? '') ?? 86.0,
      quadrilAntes: double.tryParse(json['quadril_antes']?.toString() ?? '') ?? 108.0,
      quadrilDepois: double.tryParse(json['quadril_depois']?.toString() ?? '') ?? 102.0,
      coxaAntes: double.tryParse(json['coxa_antes']?.toString() ?? '') ?? 62.0,
      coxaDepois: double.tryParse(json['coxa_depois']?.toString() ?? '') ?? 59.0,
      bracoAntes: double.tryParse(json['braco_antes']?.toString() ?? '') ?? 32.0,
      bracoDepois: double.tryParse(json['braco_depois']?.toString() ?? '') ?? 31.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'peso_atual': pesoAtual,
      'meta_peso': metaPeso,
      'cintura_antes': cinturaAntes,
      'cintura_depois': cinturaDepois,
      'quadril_antes': quadrilAntes,
      'quadril_depois': quadrilDepois,
      'coxa_antes': coxaAntes,
      'coxa_depois': coxaDepois,
      'braco_antes': bracoAntes,
      'braco_depois': bracoDepois,
    };
  }
}
