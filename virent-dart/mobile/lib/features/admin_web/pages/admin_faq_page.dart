import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../admin_web_providers.dart';


class AdminFaqPage extends ConsumerWidget {
  const AdminFaqPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminFaqProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Ошибка загрузки: $e', style: const TextStyle(color: Colors.red))),
      data: (items) Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('Faqs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: Color(0xFF333333))),
                        SizedBox(width: 12),
                        Text('Показано 1 до 20 из 56 совпадений', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 14, color: Colors.white),
                      label: const Text('Добавить faq', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B68EE),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 200,
                    height: 32,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Поиск:',
                        hintStyle: const TextStyle(fontSize: 11),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(3), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF8F9FA),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      SizedBox(width: 250, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      Expanded(child: Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                      SizedBox(width: 200, child: Text('Действия', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _faqRow('Что можно и что нельзя делать на Электросамокате?', 'Сервис предназначен для лиц 18 лет и старше, весом не более 100 кг (включая одежду). Рекомендуется использовать защиту, например, шлем. Использование Электросамоката допускается исключительно в соответствии с Правилами Дорожного Движения Республики Узбекистан, утверж...'),
                      _faqRow('Как арендовать самокат?', 'Установите приложение «ViRent» для iOS или Android. Зарегистрируйтесь. Для этого потребуется указать: номер вашего телефона, Ф.И.О, возраст и селфи. Привяжите карту оплаты. Сканируйте QR-код Электросамоката, который находится рядом с вами или введите его номер, либо найдите...'),
                      _faqRow('Можно ли арендовать несколько самокатов на один аккаунт?', 'Да, это возможно, при этом ответственность, за все арендованные Электросамокаты несет тот Пользователь, на чей аккаунт они были арендованы, даже если на самокате катался другой человек. Все правила пользования распространяются на каждый арендованный Электросамокат.'),
                      _faqRow('Как завершить аренду?', 'Завершить аренду можно в разрешенной зоне, на карте она обозначена зеленым цветом. Войдя в зону, найдите свободное пространство, где Электросамокат не будет мешать другим участникам дорожного движения. Нажмите кнопку «Завершить аренду». Сделайте необходимые фото.'),
                      _faqRow('Пауза', 'Вы можете приостановить поездку, чтобы другой человек не мог использовать Ваш самокат. Обратите внимание, что с вас будет взиматься поминутная оплата, согласно вашему тарифу (не как за саму поездку) пока ваша поездка приостановлена. Чтобы прекратить списание денег, Вам ну...'),
                      _faqRow('Повреждения', 'В случае мелких повреждений (царапина, загрязнения и прочее), которые не влияют на безопасность вождения, сфотографируйте их, после чего можете начать аренду. В случае серьезных повреждений (деформация колес или рамы самоката, не работающий курок GJ или ручки тормозо...'),
                      _faqRow('Не включается самокат', 'Пожалуйста, проверьте, что у вас выбран тариф и самокат переведён в аренду. Если ни одно из вышеперечисленных предложений не помогло решить проблему, сообщите о проблеме в службу поддержки, контакты которой указаны в приложении.'),
                      _faqRow('Проблемы с самокатом Повреждения', 'В случае мелких повреждений (царапина, загрязнения и прочее), которые не влияют на безопасность вождения, сфотографируйте их, после чего можете начать аренду. В случае серьезных повреждений (деформация колес или рамы самоката, не работающий курок GO или ручки тормозо...'),
                      _faqRow('Не включается самокат', 'Пожалуйста, проверьте, что у вас выбран тариф и самокат переведён в аренду. Если ни одно из вышеперечисленных предложений не помогло решить проблему, сообщите о проблеме в службу поддержки, контакты которой указаны в приложении.'),
                      _faqRow('Тарифы и проблемы с оплатой Стоимость аренды', 'Актуальная информация о тарифах становится доступной в приложении перед началом аренды. Тарифы могут различаться в разных регионах. Нажимая кнопку «Начать аренду» пользователь соглашается с тарифом. При начале пользования Сервисом «ViRent» на карте резервируется сум...'),
                      _faqRow('Банковские карты Как удалить карту?', 'Откройте приложение, в верхнем левом углу нажмите значок «Меню» (три полоски). Далее нажмите кнопку «Оплата». Выберите карту и нажмите на крестик в правом верхнем углу изображения вашей карты.'),
                      _faqRow('Нельзя осуществить платеж с карты', 'Не все банковские карты могут быть использованы для совершения платежей, о чём становится известно после попытки совершить платёж. У карты должна быть подключена 3ds-аутентификация. Также проверьте срок действия карты, он не должен заканчиваться в текущем месяце. Если...'),
                      _faqRow('Как связаться со службой поддержки?', 'Контакты службы поддержки указаны в приложении, для каждого региона они свои. Откройте приложение, в верхнем левом углу нажмите значок «Меню» (три полоски), меню «Помощь», выберите удобный доступный и удобный для вас способ связи.'),
                      _faqRow('Что делать, если я выехал из зоны разрешенной для поездок?', 'Приложение и самокат начнут сигнализировать о пересечении разрешенной зоны катания (обозначена синим цветом). Вернитесь обратно в зону разрешенного катания и продолжайте поездку, учитывая размеры и форму зоны. Если вы проигнорируете эти сигналы, то это будет расцене...'),
                      _faqRow('Как удалить аккаунт?', 'В верхнем левом углу нажмите значок «Меню» (три полоски), меню «Личный кабинет», нажмите значок «Удалить аккаунт».'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqRow(String name, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 250, child: Text(name, style: const TextStyle(fontSize: 11))),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 11))),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.edit, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Редактировать', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
                const SizedBox(width: 12),
                InkWell(onTap: () {}, child: const Row(children: [Icon(Icons.delete, size: 12, color: Color(0xFF3498DB)), SizedBox(width: 4), Text('Удалить', style: TextStyle(fontSize: 10, color: Color(0xFF3498DB)))])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
