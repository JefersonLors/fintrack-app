import '../../domain/utils/ocr_parser_utils.dart';

class DigitalTransferSignals {
  static bool looksLikeFiscalDocument(String text) {
    return containsAny(text, const [
      'nfc-e',
      'nf-e',
      'nota fiscal',
      'documento auxiliar',
      'consumidor eletronica',
      'chave de acesso',
      'qtd total de itens',
      'valor total r',
    ]);
  }

  static bool hasExplicitDigitalReceipt(String text) {
    return containsAny(text, const [
      'comprovante de pagamento',
      'pagamento efetuado',
      'quem recebeu',
      'quem pagou',
      'id da transacao',
      'tipo de transferencia',
    ]);
  }

  static bool hasPrimarySignal(String text) {
    return containsAny(text, const [
      'pix',
      'ted',
      'transferencia',
      'comprovante de pagamento',
      'pagamento efetuado',
      'transacao',
      'id da transacao',
      'origem',
      'destino',
      'quem recebeu',
      'quem pagou',
      'favorecido',
      'recebedor',
      'pagador',
      'estabelecimento',
    ]);
  }

  static int countStrongSignals(String text) {
    return countOccurrences(text, const [
      'pix',
      'ted',
      'doc',
      'transferencia',
      'comprovante de pagamento',
      'pagamento efetuado',
      'transacao',
      'id da transacao',
      'e2e',
      'origem',
      'destino',
      'quem recebeu',
      'quem pagou',
      'favorecido',
      'recebedor',
      'pagador',
      'estabelecimento',
      'instituicao',
      'cpf',
      'cnpj',
      'cpf/cnpj',
      'cartao',
      'codigo de autorizacao',
    ]);
  }
}
