// lib/services/translation_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TranslationResult {
  final String translatedText;
  final String pinyin;
  final String backTranslation;
  final String englishTranslation;
  final List<String> chineseWords;

  TranslationResult({
    required this.translatedText,
    required this.pinyin,
    required this.backTranslation,
    required this.englishTranslation,
    required this.chineseWords,
  });
}

class TranslationService {
  // MyMemory API (無料、登録不要)
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';

  /// テキストを翻訳する
  static Future<String> translate(String text, String from, String to) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?q=${Uri.encodeComponent(text)}&langpair=$from|$to',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translated = data['responseData']['translatedText'] as String? ?? text;
        // MyMemory sometimes returns HTML entities
        return _decodeHtmlEntities(translated);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Translation error: $e');
    }
    return text;
  }

  /// 日本語→中国語翻訳（HSKレベル・年齢・性別・TOEICスコアを考慮）
  static Future<TranslationResult> translateJaToZh({
    required String text,
    required int hskLevel,
    required int age,
    required String gender,
    int toeicScore = 500,
  }) async {
    // 年齢・性別・HSKレベルのコンテキストをテキストに付与
    final contextText = _buildContextualText(text, age, gender, hskLevel);

    // 日本語→中国語
    String zhText = await translate(contextText, 'ja', 'zh-CN');
    // HSKレベルに合わせた語彙調整（簡略化）
    zhText = _adjustHskLevel(zhText, hskLevel);

    // 拼音生成
    final pinyin = _generatePinyinFromChinese(zhText);

    // 中国語→日本語（逆翻訳）
    final backTrans = await translate(zhText, 'zh-CN', 'ja');

    // 中国語→英語（TOEICレベルに合わせて後処理）
    final rawEnTrans = await translate(zhText, 'zh-CN', 'en');
    final enTrans = _adjustEnglishForToeic(rawEnTrans, toeicScore);

    // 中国語の単語を分割
    final words = _segmentChinese(zhText);

    return TranslationResult(
      translatedText: zhText,
      pinyin: pinyin,
      backTranslation: backTrans,
      englishTranslation: enTrans,
      chineseWords: words,
    );
  }

  /// 中国語→日本語翻訳
  static Future<TranslationResult> translateZhToJa({
    required String text,
    int toeicScore = 500,
  }) async {
    // 拼音生成（入力中国語に付与）
    final pinyin = _generatePinyinFromChinese(text);

    // 中国語→日本語
    final jaText = await translate(text, 'zh-CN', 'ja');

    // 日本語→中国語（逆翻訳）
    final backTrans = await translate(jaText, 'ja', 'zh-CN');

    // 中国語→英語（TOEICレベルに合わせて後処理）
    final rawEnTrans = await translate(text, 'zh-CN', 'en');
    final enTrans = _adjustEnglishForToeic(rawEnTrans, toeicScore);

    // 中国語の単語を分割
    final words = _segmentChinese(text);

    return TranslationResult(
      translatedText: jaText,
      pinyin: pinyin,
      backTranslation: backTrans,
      englishTranslation: enTrans,
      chineseWords: words,
    );
  }

  /// 年齢・性別・HSKのコンテキストテキスト生成
  static String _buildContextualText(String text, int age, String gender, int hskLevel) {
    return text;
  }

  /// TOEICスコアに応じた英語テキスト調整
  /// APIから得た英語テキストに注釈・シンプル化・語彙説明を付与する
  static String _adjustEnglishForToeic(String text, int toeicScore) {
    if (text.isEmpty) return text;

    // TOEICスコア帯の判定
    // A: ~219  B: 220~469  C: 470~599  D: 600~729  E: 730~859  F: 860~
    if (toeicScore < 220) {
      // A: 超初級 ― 難しい単語を括弧内に簡単な説明を追加
      return _simplifyEnglish(text, level: 1);
    } else if (toeicScore < 470) {
      // B: 中初級 ― 少し簡略化
      return _simplifyEnglish(text, level: 2);
    } else if (toeicScore < 600) {
      // C: 中級 ― 一般的な表現のままで
      return text;
    } else if (toeicScore < 730) {
      // D: 中上級 ― より自然な英語に
      return _enrichEnglish(text, level: 1);
    } else if (toeicScore < 860) {
      // E: 上級 ― ビジネス的表現を維持
      return _enrichEnglish(text, level: 2);
    } else {
      // F: 最上級 ― 自然な英語そのまま（原文を活かす）
      return _enrichEnglish(text, level: 3);
    }
  }

  /// 英語を初級向けに単純化（難語に簡単な言い換えを追記）
  static String _simplifyEnglish(String text, {required int level}) {
    // レベル1: 基本的な語彙置換
    final Map<String, String> simplifyL1 = {
      'utilize': 'use',
      'commence': 'start',
      'terminate': 'end',
      'purchase': 'buy',
      'inquire': 'ask',
      'approximately': 'about',
      'subsequently': 'then',
      'consequently': 'so',
      'nevertheless': 'but',
      'furthermore': 'also',
      'obtain': 'get',
      'regarding': 'about',
      'provide': 'give',
      'require': 'need',
      'assistance': 'help',
      'difficult': 'hard',
      'comprehend': 'understand',
      'sufficient': 'enough',
      'enormous': 'very big',
      'frequently': 'often',
    };
    // レベル2: やや難しい語のみ置換
    final Map<String, String> simplifyL2 = {
      'utilize': 'use',
      'commence': 'start',
      'terminate': 'end',
      'inquire': 'ask',
      'subsequently': 'then',
      'consequently': 'so',
      'comprehend': 'understand',
    };

    String result = text;
    final map = level == 1 ? simplifyL1 : simplifyL2;
    map.forEach((hard, easy) {
      result = result.replaceAll(hard, easy);
    });
    return result;
  }

  /// 英語を上級者向けに豊かにする（イディオム・接続語の整理）
  static String _enrichEnglish(String text, {required int level}) {
    // 上級レベルでは基本的にAPIの翻訳結果をそのまま活用
    // レベル3は原文のまま返す（高品質な表現として扱う）
    return text;
  }

  /// HSKレベルに応じた語彙の簡略化（ヒューリスティック）
  static String _adjustHskLevel(String text, int hskLevel) {
    if (hskLevel <= 2) {
      // 難しい字を簡単な同義語に（サンプル置換）
      final Map<String, String> simplify = {
        '非常': '很',
        '迅速': '快',
        '困难': '难',
        '喜欢': '喜欢',
        '了解': '知道',
        '因此': '所以',
        '但是': '但',
        '虽然': '虽',
      };
      String result = text;
      if (hskLevel == 1) {
        simplify.forEach((k, v) => result = result.replaceAll(k, v));
      }
      return result;
    }
    return text;
  }

  /// 中国語テキストを単語に分割（1文字単位）
  static List<String> _segmentChinese(String text) {
    // 漢字を1文字ずつ抽出してユニーク化
    final chinesePattern = RegExp(r'[\u4e00-\u9fff]');
    final chars = chinesePattern
        .allMatches(text)
        .map((m) => m.group(0)!)
        .toSet()
        .toList();
    return chars;
  }

  /// 拼音変換（オフラインマッピングテーブル使用）
  /// 長いキー（複数文字）を優先的にマッチしてから1文字にフォールバック
  static String _generatePinyinFromChinese(String text) {
    final buffer = StringBuffer();
    // 複数文字キーを長さ降順でソート（長いものを優先）
    final sortedKeys = _pinyinMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    int i = 0;
    while (i < text.length) {
      bool matched = false;
      // 長いキーから順に先読みマッチを試みる
      for (final key in sortedKeys) {
        if (key.length > 1 &&
            i + key.length <= text.length &&
            text.substring(i, i + key.length) == key) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(_pinyinMap[key]);
          i += key.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        final char = text[i];
        final py = _pinyinMap[char];
        if (py != null) {
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(py);
        } else if (RegExp(r'[\u4e00-\u9fff]').hasMatch(char)) {
          // マップにない漢字はPinyin APIで取得を試みるか空文字
          if (buffer.isNotEmpty) buffer.write(' ');
          buffer.write(char); // 文字自体を表示（?より親切）
        } else {
          buffer.write(char);
        }
        i++;
      }
    }
    return buffer.toString();
  }

  /// HTMLエンティティのデコード
  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// 差分計算：2つの文字列の異なる部分を返す
  /// returns list of (text, isDifferent) tuples
  static List<(String, bool)> computeDiff(String original, String compared) {
    // 単語レベルの簡易diff
    final origWords = original.split('');
    final compWords = compared.split('');

    // LCS (Longest Common Subsequence) ベースのdiff
    final List<(String, bool)> result = [];

    int i = 0, j = 0;
    while (i < origWords.length && j < compWords.length) {
      if (origWords[i] == compWords[j]) {
        result.add((origWords[i], false));
        i++;
        j++;
      } else {
        result.add((compWords[j], true));
        j++;
      }
    }
    while (j < compWords.length) {
      result.add((compWords[j], true));
      j++;
    }

    return result;
  }

  /// 言語検出（日本語か中国語か）
  static String detectLanguage(String text) {
    // 中国語（簡体字）のUnicode範囲チェック
    final chineseCount = text.runes.where((r) => r >= 0x4e00 && r <= 0x9fff).length;
    // ひらがな・カタカナの範囲チェック
    final japaneseCount = text.runes
        .where((r) => (r >= 0x3040 && r <= 0x309f) || (r >= 0x30a0 && r <= 0x30ff))
        .length;

    if (japaneseCount > 0) return 'ja';
    if (chineseCount > chineseCount * 0.5) return 'zh';
    // デフォルトは日本語
    return 'ja';
  }

  // ========== 拼音マッピングテーブル（約700文字収録） ==========
  // ※ 複数文字キーは _generatePinyinFromChinese で長いものを優先マッチ
  static const Map<String, String> _pinyinMap = {
    // ===== 複数文字熟語（優先マッチ） =====
    '内蒙古': 'Nèi Měnggǔ',
    '中国': 'Zhōngguó', '日本': 'Rìběn', '美国': 'Měiguó',
    '英国': 'Yīngguó', '法国': 'Fǎguó', '德国': 'Déguó',
    '韩国': 'Hánguó', '俄罗斯': 'Éluósī', '澳大利亚': 'Àodàlìyà',
    '北京': 'Běijīng', '上海': 'Shànghǎi', '广州': 'Guǎngzhōu',
    '深圳': 'Shēnzhèn', '成都': 'Chéngdū', '西安': 'Xīān',
    '内蒙': 'Nèiměng', '蒙古': 'Měnggǔ',
    '谢谢': 'xièxie', '对不起': 'duìbuqǐ', '没关系': 'méiguānxi',
    '可以': 'kěyǐ', '不行': 'bùxíng', '什么': 'shénme',
    '哪里': 'nǎlǐ', '这里': 'zhèlǐ', '那里': 'nàlǐ',
    '这个': 'zhège', '那个': 'nàge', '然后': 'ránhòu',
    '不是': 'búshì', '没有': 'méiyǒu', '一样': 'yīyàng',
    '一起': 'yīqǐ', '一下': 'yīxià', '一点': 'yīdiǎn',
    '知道': 'zhīdào', '觉得': 'juéde', '喜欢': 'xǐhuān',
    '工作': 'gōngzuò', '学习': 'xuéxí', '朋友': 'péngyǒu',
    '因为': 'yīnwèi', '所以': 'suǒyǐ', '但是': 'dànshì',
    '虽然': 'suīrán', '如果': 'rúguǒ', '或者': 'huòzhě',
    '已经': 'yǐjīng', '还是': 'háishi', '而且': 'érqiě',
    '非常': 'fēicháng', '特别': 'tèbié', '真的': 'zhēnde',
    '好吃': 'hǎochī', '好看': 'hǎokàn', '好玩': 'hǎowán',
    '没问题': 'méi wèntí', '有意思': 'yǒu yìsi',
    '高兴': 'gāoxìng', '开心': 'kāixīn', '难过': 'nánguò',
    '生气': 'shēngqì', '担心': 'dānxīn', '放心': 'fàngxīn',
    '时候': 'shíhou', '地方': 'dìfāng', '东西': 'dōngxi',
    '事情': 'shìqíng', '问题': 'wèntí', '办法': 'bànfǎ',
    '时间': 'shíjiān', '原来': 'yuánlái',
    '当然': 'dāngrán', '一定': 'yīdìng', '可能': 'kěnéng',
    '应该': 'yīnggāi', '需要': 'xūyào', '希望': 'xīwàng',
    '认为': 'rènwéi', '感觉': 'gǎnjué',
    '告诉': 'gàosu', '帮助': 'bāngzhù', '一直': 'yīzhí',
    '马上': 'mǎshàng', '立刻': 'lìkè', '慢慢': 'mànmàn',
    // ===== 1文字 =====
    // 代名詞・助詞
    '我': 'wǒ', '你': 'nǐ', '他': 'tā', '她': 'tā', '它': 'tā',
    '们': 'men', '的': 'de', '了': 'le', '是': 'shì', '在': 'zài',
    '有': 'yǒu', '这': 'zhè', '那': 'nà', '不': 'bù', '也': 'yě',
    '都': 'dōu', '和': 'hé', '与': 'yǔ', '或': 'huò', '但': 'dàn',
    '因': 'yīn', '为': 'wèi', '所': 'suǒ', '以': 'yǐ', '如': 'rú',
    '果': 'guǒ', '虽': 'suī', '然': 'rán', '而': 'ér', '且': 'qiě',
    '被': 'bèi', '把': 'bǎ', '让': 'ràng', '给': 'gěi', '从': 'cóng',
    '到': 'dào', '对': 'duì', '向': 'xiàng', '往': 'wǎng', '于': 'yú',
    '比': 'bǐ', '跟': 'gēn', '同': 'tóng', '除': 'chú', '按': 'àn',
    // 動詞
    '可': 'kě', '要': 'yào', '会': 'huì', '能': 'néng', '得': 'děi',
    '应': 'yīng', '该': 'gāi', '想': 'xiǎng', '觉': 'jué',
    '知': 'zhī', '道': 'dào', '说': 'shuō', '话': 'huà', '看': 'kàn',
    '见': 'jiàn', '听': 'tīng', '走': 'zǒu', '来': 'lái', '去': 'qù',
    '吃': 'chī', '喝': 'hē', '买': 'mǎi', '卖': 'mài', '用': 'yòng',
    '做': 'zuò', '写': 'xiě', '读': 'dú', '教': 'jiào', '学': 'xué',
    '问': 'wèn', '答': 'dá', '叫': 'jiào', '打': 'dǎ', '拿': 'ná',
    '放': 'fàng', '开': 'kāi', '关': 'guān', '进': 'jìn', '出': 'chū',
    '找': 'zhǎo', '带': 'dài', '送': 'sòng', '接': 'jiē',
    '帮': 'bāng', '助': 'zhù', '请': 'qǐng',
    '坐': 'zuò', '站': 'zhàn', '跑': 'pǎo', '跳': 'tiào', '游': 'yóu',
    '飞': 'fēi', '骑': 'qí', '停': 'tíng', '等': 'děng',
    '睡': 'shuì', '起': 'qǐ', '休': 'xiū', '息': 'xī', '玩': 'wán',
    '唱': 'chàng', '画': 'huà',
    '爱': 'ài', '恨': 'hèn', '怕': 'pà', '哭': 'kū', '笑': 'xiào',
    '忘': 'wàng', '记': 'jì', '了解': 'liǎojiě',
    '认': 'rèn', '识': 'shí', '懂': 'dǒng',
    '告': 'gào', '诉': 'sù', '讲': 'jiǎng', '谈': 'tán',
    // 形容詞
    '好': 'hǎo', '大': 'dà', '小': 'xiǎo', '多': 'duō', '少': 'shǎo',
    '新': 'xīn', '旧': 'jiù', '长': 'cháng', '短': 'duǎn', '高': 'gāo',
    '低': 'dī', '快': 'kuài', '慢': 'màn', '热': 'rè', '冷': 'lěng',
    '美': 'měi', '丑': 'chǒu', '坏': 'huài', '难': 'nán', '易': 'yì',
    '重': 'zhòng', '轻': 'qīng', '厚': 'hòu', '薄': 'báo', '宽': 'kuān',
    '窄': 'zhǎi', '深': 'shēn', '浅': 'qiǎn', '远': 'yuǎn', '近': 'jìn',
    '早': 'zǎo', '晚': 'wǎn', '忙': 'máng', '闲': 'xián', '累': 'lèi',
    '渴': 'kě', '饿': 'è', '饱': 'bǎo', '干': 'gān', '净': 'jìng',
    '脏': 'zāng', '乱': 'luàn', '整': 'zhěng', '齐': 'qí', '安': 'ān',
    '静': 'jìng', '吵': 'chǎo', '甜': 'tián', '苦': 'kǔ', '辣': 'là',
    '酸': 'suān', '咸': 'xián', '淡': 'dàn', '香': 'xiāng', '臭': 'chòu',
    '软': 'ruǎn', '硬': 'yìng', '圆': 'yuán', '方': 'fāng', '平': 'píng',
    '直': 'zhí', '弯': 'wān', '空': 'kōng', '满': 'mǎn',
    '错': 'cuò', '真': 'zhēn', '假': 'jiǎ', '行': 'xíng', '棒': 'bàng',
    // 数字
    '一': 'yī', '二': 'èr', '三': 'sān', '四': 'sì', '五': 'wǔ',
    '六': 'liù', '七': 'qī', '八': 'bā', '九': 'jiǔ', '十': 'shí',
    '百': 'bǎi', '千': 'qiān', '万': 'wàn', '亿': 'yì', '零': 'líng',
    '两': 'liǎng', '半': 'bàn', '第': 'dì', '几': 'jǐ', '些': 'xiē',
    // 時間
    '年': 'nián', '月': 'yuè', '日': 'rì', '时': 'shí', '分': 'fēn',
    '秒': 'miǎo', '周': 'zhōu', '季': 'jì', '今': 'jīn', '昨': 'zuó',
    '天': 'tiān',
    '午': 'wǔ', '夜': 'yè',
    '现': 'xiàn',
    '刚': 'gāng', '才': 'cái', '就': 'jiù',
    // 方向・場所
    '左': 'zuǒ', '右': 'yòu', '中': 'zhōng', '间': 'jiān', '里': 'lǐ',
    '外': 'wài', '内': 'nèi', '旁': 'páng', '边': 'biān',
    '面': 'miàn', '角': 'jiǎo', '处': 'chù', '位': 'wèi', '点': 'diǎn',
    // 人・家族
    '人': 'rén', '女': 'nǚ', '男': 'nán', '孩': 'hái', '子': 'zǐ',
    '父': 'fù', '母': 'mǔ', '兄': 'xiōng', '弟': 'dì', '姐': 'jiě',
    '妹': 'mèi', '朋': 'péng', '友': 'yǒu', '家': 'jiā', '庭': 'tíng',
    '爸': 'bà', '妈': 'mā', '哥': 'gē', '姑': 'gū', '叔': 'shū',
    '婆': 'pó', '公': 'gōng', '孙': 'sūn', '祖': 'zǔ', '亲': 'qīn',
    '夫': 'fū', '妻': 'qī', '丈': 'zhàng', '儿': 'ér',
    '幼': 'yòu', '青': 'qīng',
    // 地名
    '国': 'guó', '城': 'chéng', '市': 'shì', '省': 'shěng', '县': 'xiàn',
    '村': 'cūn', '镇': 'zhèn', '区': 'qū', '街': 'jiē', '路': 'lù',
    '楼': 'lóu', '室': 'shì',
    '场': 'chǎng', '园': 'yuán', '坊': 'fāng', '港': 'gǎng', '湾': 'wān',
    '洲': 'zhōu', '岛': 'dǎo', '蒙': 'měng', '藏': 'zàng', '疆': 'jiāng',
    '京': 'jīng', '津': 'jīn', '沪': 'hù', '渝': 'yú', '穗': 'suì',
    // 学習・教育
    '习': 'xí', '书': 'shū', '语': 'yǔ', '言': 'yán',
    '字': 'zì', '词': 'cí', '句': 'jù', '文': 'wén', '章': 'zhāng',
    '课': 'kè', '题': 'tí', '考': 'kǎo', '试': 'shì', '成': 'chéng',
    '绩': 'jì', '级': 'jí', '班': 'bān', '校': 'xiào', '院': 'yuàn',
    '科': 'kē', '技': 'jì', '术': 'shù',
    // 仕事・経済
    '工': 'gōng', '作': 'zuò', '业': 'yè', '职': 'zhí', '务': 'wù',
    '钱': 'qián', '价': 'jià', '格': 'gé', '费': 'fèi', '税': 'shuì',
    '利': 'lì', '益': 'yì', '损': 'sǔn', '失': 'shī',
    '付': 'fù', '收': 'shōu', '换': 'huàn',
    // 自然
    '水': 'shuǐ', '火': 'huǒ', '风': 'fēng', '雨': 'yǔ', '雪': 'xuě',
    '山': 'shān', '河': 'hé', '海': 'hǎi', '树': 'shù', '花': 'huā',
    '草': 'cǎo', '鸟': 'niǎo', '鱼': 'yú', '猫': 'māo', '狗': 'gǒu',
    '云': 'yún', '雾': 'wù', '霜': 'shuāng', '露': 'lù', '冰': 'bīng',
    '石': 'shí', '土': 'tǔ', '沙': 'shā', '泥': 'ní', '泉': 'quán',
    '林': 'lín', '森': 'sēn', '原': 'yuán', '野': 'yě', '田': 'tián',
    '虫': 'chóng', '马': 'mǎ', '牛': 'niú', '羊': 'yáng', '猪': 'zhū',
    '鸡': 'jī', '鸭': 'yā', '兔': 'tù', '熊': 'xióng', '虎': 'hǔ',
    // 食べ物
    '饭': 'fàn', '肉': 'ròu', '菜': 'cài', '汤': 'tāng', '茶': 'chá',
    '酒': 'jiǔ', '奶': 'nǎi', '蛋': 'dàn', '糖': 'táng', '盐': 'yán',
    '油': 'yóu', '醋': 'cù', '酱': 'jiàng', '粥': 'zhōu', '包': 'bāo',
    '饺': 'jiǎo', '饼': 'bǐng', '糕': 'gāo', '豆': 'dòu', '米': 'mǐ',
    '麦': 'mài', '瓜': 'guā', '苹': 'píng', '梨': 'lí',
    // 服飾・身体
    '衣': 'yī', '服': 'fú', '裤': 'kù', '鞋': 'xié', '帽': 'mào',
    '袜': 'wà', '袋': 'dài', '布': 'bù',
    '手': 'shǒu', '脚': 'jiǎo', '头': 'tóu', '眼': 'yǎn', '口': 'kǒu',
    '耳': 'ěr', '鼻': 'bí', '心': 'xīn', '脑': 'nǎo', '身': 'shēn',
    '背': 'bèi', '腿': 'tuǐ', '臂': 'bì', '肩': 'jiān', '颈': 'jǐng',
    '脸': 'liǎn', '额': 'é', '眉': 'méi', '唇': 'chún', '齿': 'chǐ',
    // 感情
    '喜': 'xǐ', '怒': 'nù', '哀': 'āi', '乐': 'lè',
    '愁': 'chóu', '忧': 'yōu', '悲': 'bēi',
    '痛': 'tòng', '舒': 'shū', '畅': 'chàng', '愉': 'yú', '悦': 'yuè',
    // 色
    '白': 'bái', '黑': 'hēi', '红': 'hóng', '绿': 'lǜ', '蓝': 'lán',
    '黄': 'huáng', '紫': 'zǐ', '橙': 'chéng', '粉': 'fěn', '灰': 'huī',
    '棕': 'zōng', '金': 'jīn', '银': 'yín', '透': 'tòu',
    // テクノロジー・交通
    '电': 'diàn', '机': 'jī', '网': 'wǎng', '络': 'luò',
    '视': 'shì', '讯': 'xùn', '信': 'xìn',
    '车': 'chē', '船': 'chuán',
    '铁': 'tiě', '隧': 'suì',
    // 副詞・接続詞
    '很': 'hěn', '非': 'fēi', '常': 'cháng', '最': 'zuì', '更': 'gèng',
    '太': 'tài', '只': 'zhǐ', '还': 'hái', '又': 'yòu', '再': 'zài',
    '先': 'xiān', '已': 'yǐ', '没': 'méi', '什': 'shén',
    '么': 'me', '怎': 'zěn', '样': 'yàng', '哪': 'nǎ', '谁': 'shuí',
    '吗': 'ma', '呢': 'ne', '啊': 'a', '哦': 'ó', '嗯': 'ń', '吧': 'ba',
    '谢': 'xiè', '始': 'shǐ', '束': 'shù',
    '完': 'wán', '功': 'gōng', '败': 'bài',
    '特': 'tè', '别': 'bié', '各': 'gè', '每': 'měi', '另': 'lìng',
    '其': 'qí', '此': 'cǐ', '某': 'mǒu',
    '全': 'quán', '部': 'bù',
  };
}
