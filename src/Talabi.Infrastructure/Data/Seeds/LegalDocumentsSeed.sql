-- Yasal Belgeler için Örnek Seed Data
-- Bu SQL script'i veritabanında çalıştırarak örnek yasal belgeleri ekleyebilirsiniz
-- NOT: Unicode karakterler (Türkçe, Arapça vb.) için stringlerin başına 'N' eklenmiştir.

-- Önce mevcut verileri temizleyelim (İsteğe bağlı, duplicate hatası almamak için)
-- DELETE FROM LegalDocuments;

-- Türkçe Belgeler
INSERT INTO LegalDocuments (Id, Type, LanguageCode, Title, Content, LastUpdated, CreatedAt)
VALUES 
-- Kullanım Şartları (TR)
(NEWID(), N'terms-of-use', N'tr', N'Kullanım Şartları', 
N'<h1>Kullanım Şartları</h1>
<p>Son Güncellenme: 27 Kasım 2024</p>

<h2>1. Genel Hükümler</h2>
<p>Talabi platformunu kullanarak aşağıdaki şartları kabul etmiş sayılırsınız:</p>
<ul>
<li>Platform üzerinden yapılan tüm işlemlerden sorumlusunuz</li>
<li>Hesap bilgilerinizi gizli tutmakla yükümlüsünüz</li>
<li>Yasalara aykırı kullanım kesinlikle yasaktır</li>
</ul>

<h2>2. Kullanıcı Yükümlülükleri</h2>
<p>Kullanıcılar platform üzerinde:</p>
<ul>
<li>Doğru ve güncel bilgi vermekle yükümlüdür</li>
<li>Diğer kullanıcılara saygılı davranmalıdır</li>
<li>Platform kurallarına uymalıdır</li>
</ul>

<h2>3. Hizmet Kapsamı</h2>
<p>Talabi, yemek siparişi ve teslimat hizmeti sunan bir platformdur. Platform üzerinden verilen siparişler için işletmeler ve kuryeler sorumludur.</p>

<h2>4. Sorumluluk Reddi</h2>
<p>Platform, üçüncü taraf hizmet sağlayıcıların (restoranlar, kuryeler) eylemlerinden sorumlu değildir.</p>

<h2>5. İletişim</h2>
<p>Sorularınız için: <a href="mailto:destek@talabi.com">destek@talabi.com</a></p>', 
GETUTCDATE(), GETUTCDATE()),

-- Gizlilik Politikası (TR)
(NEWID(), N'privacy-policy', N'tr', N'Gizlilik Politikası',
N'<h1>Gizlilik Politikası</h1>
<p>Son Güncellenme: 27 Kasım 2024</p>

<h2>1. Toplanan Bilgiler</h2>
<p>Talabi olarak aşağıdaki bilgileri topluyoruz:</p>
<ul>
<li>Ad, soyad, e-posta adresi</li>
<li>Telefon numarası</li>
<li>Teslimat adresleri</li>
<li>Sipariş geçmişi</li>
<li>Ödeme bilgileri (şifreli olarak)</li>
</ul>

<h2>2. Bilgilerin Kullanımı</h2>
<p>Toplanan bilgiler şu amaçlarla kullanılır:</p>
<ul>
<li>Sipariş işlemlerinin gerçekleştirilmesi</li>
<li>Müşteri hizmetleri desteği</li>
<li>Platform iyileştirmeleri</li>
<li>Yasal yükümlülüklerin yerine getirilmesi</li>
</ul>

<h2>3. Bilgi Güvenliği</h2>
<p>Verileriniz SSL şifreleme ile korunmaktadır. Ödeme bilgileri PCI-DSS standartlarına uygun olarak saklanır.</p>

<h2>4. Üçüncü Taraflarla Paylaşım</h2>
<p>Bilgileriniz yalnızca sipariş teslimatı için gerekli olan restoranlar ve kuryelerle paylaşılır.</p>

<h2>5. Haklarınız</h2>
<p>KVKK kapsamında verilerinize erişim, düzeltme ve silme hakkına sahipsiniz.</p>',
GETUTCDATE(), GETUTCDATE()),

-- İade Politikası (TR)
(NEWID(), N'refund-policy', N'tr', N'İade ve İptal Politikası',
N'<h1>İade ve İptal Politikası</h1>
<p>Son Güncellenme: 27 Kasım 2024</p>

<h2>1. Sipariş İptali</h2>
<p>Siparişinizi aşağıdaki durumlarda iptal edebilirsiniz:</p>
<ul>
<li>Sipariş henüz hazırlanmaya başlanmadıysa</li>
<li>Restoran siparişi onaylamadıysa</li>
<li>Kurye siparişi teslim almadıysa</li>
</ul>

<h2>2. İade Koşulları</h2>
<p>İade talepleri şu durumlarda kabul edilir:</p>
<ul>
<li>Yanlış ürün teslim edilmişse</li>
<li>Ürün bozuk veya eksik gelmişse</li>
<li>Teslimat süresi aşırı geciktiyse</li>
</ul>

<h2>3. İade Süreci</h2>
<ol>
<li>Müşteri hizmetleri ile iletişime geçin</li>
<li>Sorun fotoğraflarla belgelendirin</li>
<li>İade talebiniz 24 saat içinde değerlendirilir</li>
<li>Onaylanan iadeler 3-5 iş günü içinde hesabınıza yansır</li>
</ol>

<h2>4. İade Edilemeyen Durumlar</h2>
<ul>
<li>Teslimattan 2 saat sonra yapılan talepler</li>
<li>Kişisel beğeni farklılıkları</li>
<li>Müşteri hatası nedeniyle yanlış sipariş</li>
</ul>',
GETUTCDATE(), GETUTCDATE()),

-- Mesafeli Satış Sözleşmesi (TR)
(NEWID(), N'distance-sales-agreement', N'tr', N'Mesafeli Satış Sözleşmesi',
N'<h1>Mesafeli Satış Sözleşmesi</h1>
<p>6502 sayılı Tüketicinin Korunması Hakkında Kanun uyarınca</p>

<h2>1. Taraflar</h2>
<p><strong>SATICI:</strong> Talabi Teknoloji A.Ş.<br>
<strong>ALICI:</strong> Platform üzerinden sipariş veren kullanıcı</p>

<h2>2. Sözleşme Konusu</h2>
<p>Bu sözleşme, ALICI''nın SATICI''ya ait internet sitesi üzerinden elektronik ortamda siparişini verdiği yemek ürünlerinin satışı ve teslimi ile ilgili tarafların hak ve yükümlülüklerini düzenler.</p>

<h2>3. Ürün Bilgileri</h2>
<p>Sipariş edilen ürünlerin özellikleri, fiyatları ve teslimat bilgileri sipariş öncesi ekranda gösterilir.</p>

<h2>4. Teslimat</h2>
<ul>
<li>Teslimat süresi sipariş sırasında belirtilir</li>
<li>Teslimat adresi ALICI tarafından belirlenir</li>
<li>Teslimat ücreti sipariş tutarına eklenir</li>
</ul>

<h2>5. Cayma Hakkı</h2>
<p>Gıda ürünlerinin özelliği gereği cayma hakkı kullanılamaz (6502 sayılı kanun md. 15/1-d).</p>

<h2>6. Ödeme</h2>
<p>Ödeme, sipariş sırasında seçilen yöntemle (kredi kartı, nakit vb.) gerçekleştirilir.</p>

<h2>7. Uyuşmazlık Çözümü</h2>
<p>İşbu sözleşmeden kaynaklanan uyuşmazlıklarda Tüketici Hakem Heyetleri ve Tüketici Mahkemeleri yetkilidir.</p>',
GETUTCDATE(), GETUTCDATE());

-- İngilizce Belgeler
INSERT INTO LegalDocuments (Id, Type, LanguageCode, Title, Content, LastUpdated, CreatedAt)
VALUES 
-- Terms of Use (EN)
(NEWID(), N'terms-of-use', N'en', N'Terms of Use',
N'<h1>Terms of Use</h1>
<p>Last Updated: November 27, 2024</p>

<h2>1. General Terms</h2>
<p>By using the Talabi platform, you agree to the following terms:</p>
<ul>
<li>You are responsible for all activities under your account</li>
<li>You must keep your account credentials confidential</li>
<li>Illegal use is strictly prohibited</li>
</ul>

<h2>2. User Obligations</h2>
<p>Users must:</p>
<ul>
<li>Provide accurate and up-to-date information</li>
<li>Treat other users with respect</li>
<li>Comply with platform rules</li>
</ul>

<h2>3. Service Scope</h2>
<p>Talabi is a platform for food ordering and delivery services. Restaurants and couriers are responsible for orders placed through the platform.</p>

<h2>4. Disclaimer</h2>
<p>The platform is not responsible for the actions of third-party service providers (restaurants, couriers).</p>

<h2>5. Contact</h2>
<p>For questions: <a href="mailto:support@talabi.com">support@talabi.com</a></p>',
GETUTCDATE(), GETUTCDATE()),

-- Privacy Policy (EN)
(NEWID(), N'privacy-policy', N'en', N'Privacy Policy',
N'<h1>Privacy Policy</h1>
<p>Last Updated: November 27, 2024</p>

<h2>1. Information We Collect</h2>
<p>Talabi collects the following information:</p>
<ul>
<li>Name, email address</li>
<li>Phone number</li>
<li>Delivery addresses</li>
<li>Order history</li>
<li>Payment information (encrypted)</li>
</ul>

<h2>2. Use of Information</h2>
<p>Collected information is used for:</p>
<ul>
<li>Processing orders</li>
<li>Customer service support</li>
<li>Platform improvements</li>
<li>Legal compliance</li>
</ul>

<h2>3. Data Security</h2>
<p>Your data is protected with SSL encryption. Payment information is stored in compliance with PCI-DSS standards.</p>

<h2>4. Third-Party Sharing</h2>
<p>Your information is only shared with restaurants and couriers necessary for order delivery.</p>

<h2>5. Your Rights</h2>
<p>You have the right to access, correct, and delete your data under applicable data protection laws.</p>',
GETUTCDATE(), GETUTCDATE()),

-- Refund Policy (EN)
(NEWID(), N'refund-policy', N'en', N'Refund Policy',
N'<h1>Refund Policy</h1>
<p>Last Updated: November 27, 2024</p>

<h2>1. Order Cancellation</h2>
<p>You can cancel your order if:</p>
<ul>
<li>The order has not started being prepared</li>
<li>The restaurant has not confirmed the order</li>
<li>The courier has not picked up the order</li>
</ul>

<h2>2. Refund Conditions</h2>
<p>Refund requests are accepted when:</p>
<ul>
<li>Wrong item was delivered</li>
<li>Item is damaged or incomplete</li>
<li>Delivery was excessively delayed</li>
</ul>

<h2>3. Refund Process</h2>
<ol>
<li>Contact customer service</li>
<li>Document the issue with photos</li>
<li>Your request will be reviewed within 24 hours</li>
<li>Approved refunds are processed within 3-5 business days</li>
</ol>

<h2>4. Non-Refundable Cases</h2>
<ul>
<li>Requests made 2 hours after delivery</li>
<li>Personal taste preferences</li>
<li>Wrong order due to customer error</li>
</ul>',
GETUTCDATE(), GETUTCDATE()),

-- Distance Sales Agreement (EN)
(NEWID(), N'distance-sales-agreement', N'en', N'Distance Sales Agreement',
N'<h1>Distance Sales Agreement</h1>
<p>In accordance with Consumer Protection Law</p>

<h2>1. Parties</h2>
<p><strong>SELLER:</strong> Talabi Technology Inc.<br>
<strong>BUYER:</strong> User placing order through the platform</p>

<h2>2. Subject of Agreement</h2>
<p>This agreement regulates the rights and obligations of the parties regarding the sale and delivery of food products ordered by the BUYER through the SELLER''s website.</p>

<h2>3. Product Information</h2>
<p>Product specifications, prices, and delivery information are displayed before ordering.</p>

<h2>4. Delivery</h2>
<ul>
<li>Delivery time is specified during ordering</li>
<li>Delivery address is determined by the BUYER</li>
<li>Delivery fee is added to the order total</li>
</ul>

<h2>5. Right of Withdrawal</h2>
<p>Due to the nature of food products, the right of withdrawal cannot be exercised.</p>

<h2>6. Payment</h2>
<p>Payment is made using the method selected during ordering (credit card, cash, etc.).</p>

<h2>7. Dispute Resolution</h2>
<p>Consumer Arbitration Committees and Consumer Courts have jurisdiction over disputes arising from this agreement.</p>',
GETUTCDATE(), GETUTCDATE());

-- Arabic Documents
INSERT INTO LegalDocuments (Id, Type, LanguageCode, Title, Content, LastUpdated, CreatedAt)
VALUES 
-- Terms of Use (AR)
(NEWID(), N'terms-of-use', N'ar', N'شروط الاستخدام',
N'<h1>شروط الاستخدام</h1>
<p>آخر تحديث: 27 نوفمبر 2024</p>

<h2>1. أحكام عامة</h2>
<p>باستخدام منصة Talabi، فإنك توافق على الشروط التالية:</p>
<ul>
<li>أنت مسؤول عن جميع الأنشطة التي تتم تحت حسابك</li>
<li>يجب عليك الحفاظ على سرية بيانات اعتماد حسابك</li>
<li>الاستخدام غير القانوني ممنوع منعاً باتاً</li>
</ul>

<h2>2. التزامات المستخدم</h2>
<p>يجب على المستخدمين:</p>
<ul>
<li>تقديم معلومات دقيقة ومحدثة</li>
<li>معاملة المستخدمين الآخرين باحترام</li>
<li>الامتثال لقواعد المنصة</li>
</ul>

<h2>3. نطاق الخدمة</h2>
<p>Talabi هي منصة لطلب الطعام وخدمات التوصيل. المطاعم والسائقون مسؤولون عن الطلبات المقدمة عبر المنصة.</p>

<h2>4. إخلاء المسؤولية</h2>
<p>المنصة غير مسؤولة عن تصرفات مقدمي الخدمات من الطرف الثالث (المطاعم، السائقين).</p>

<h2>5. الاتصال</h2>
<p>للأسئلة: <a href="mailto:support@talabi.com">support@talabi.com</a></p>',
GETUTCDATE(), GETUTCDATE()),

-- Privacy Policy (AR)
(NEWID(), N'privacy-policy', N'ar', N'سياسة الخصوصية',
N'<h1>سياسة الخصوصية</h1>
<p>آخر تحديث: 27 نوفمبر 2024</p>

<h2>1. المعلومات التي نجمعها</h2>
<p>تجمع Talabi المعلومات التالية:</p>
<ul>
<li>الاسم، عنوان البريد الإلكتروني</li>
<li>رقم الهاتف</li>
<li>عناوين التوصيل</li>
<li>سجل الطلبات</li>
<li>معلومات الدفع (مشفرة)</li>
</ul>

<h2>2. استخدام المعلومات</h2>
<p>تستخدم المعلومات التي تم جمعها من أجل:</p>
<ul>
<li>معالجة الطلبات</li>
<li>دعم خدمة العملاء</li>
<li>تحسينات المنصة</li>
<li>الامتثال القانوني</li>
</ul>

<h2>3. أمن البيانات</h2>
<p>بياناتك محمية بتشفير SSL. يتم تخزين معلومات الدفع وفقاً لمعايير PCI-DSS.</p>

<h2>4. المشاركة مع أطراف ثالثة</h2>
<p>تتم مشاركة معلوماتك فقط مع المطاعم والسائقين الضروريين لتوصيل الطلب.</p>

<h2>5. حقوقك</h2>
<p>لديك الحق في الوصول إلى بياناتك وتصحيحها وحذفها بموجب قوانين حماية البيانات المعمول بها.</p>',
GETUTCDATE(), GETUTCDATE()),

-- Refund Policy (AR)
(NEWID(), N'refund-policy', N'ar', N'سياسة الاسترداد',
N'<h1>سياسة الاسترداد</h1>
<p>آخر تحديث: 27 نوفمبر 2024</p>

<h2>1. إلغاء الطلب</h2>
<p>يمكنك إلغاء طلبك إذا:</p>
<ul>
<li>لم يبدأ تحضير الطلب</li>
<li>لم يؤكد المطعم الطلب</li>
<li>لم يستلم السائق الطلب</li>
</ul>

<h2>2. شروط الاسترداد</h2>
<p>يتم قبول طلبات الاسترداد عندما:</p>
<ul>
<li>تم تسليم منتج خاطئ</li>
<li>المنتج تالف أو غير مكتمل</li>
<li>تأخر التسليم بشكل مفرط</li>
</ul>

<h2>3. عملية الاسترداد</h2>
<ol>
<li>اتصل بخدمة العملاء</li>
<li>وثق المشكلة بالصور</li>
<li>سيتم مراجعة طلبك خلال 24 ساعة</li>
<li>تتم معالجة المبالغ المستردة المعتمدة خلال 3-5 أيام عمل</li>
</ol>

<h2>4. حالات غير قابلة للاسترداد</h2>
<ul>
<li>الطلبات المقدمة بعد ساعتين من التسليم</li>
<li>تفضيلات الذوق الشخصي</li>
<li>طلب خاطئ بسبب خطأ العميل</li>
</ul>',
GETUTCDATE(), GETUTCDATE()),

-- Distance Sales Agreement (AR)
(NEWID(), N'distance-sales-agreement', N'ar', N'اتفاقية البيع عن بعد',
N'<h1>اتفاقية البيع عن بعد</h1>
<p>وفقاً لقانون حماية المستهلك</p>

<h2>1. الأطراف</h2>
<p><strong>البائع:</strong> شركة Talabi للتكنولوجيا<br>
<strong>المشتري:</strong> المستخدم الذي يقدم الطلب عبر المنصة</p>

<h2>2. موضوع الاتفاقية</h2>
<p>تنظم هذه الاتفاقية حقوق والتزامات الأطراف فيما يتعلق ببيع وتسليم المنتجات الغذائية التي يطلبها المشتري عبر موقع البائع.</p>

<h2>3. معلومات المنتج</h2>
<p>يتم عرض مواصفات المنتج والأسعار ومعلومات التسليم قبل الطلب.</p>

<h2>4. التسليم</h2>
<ul>
<li>يتم تحديد وقت التسليم أثناء الطلب</li>
<li>يتم تحديد عنوان التسليم من قبل المشتري</li>
<li>تضاف رسوم التوصيل إلى إجمالي الطلب</li>
</ul>

<h2>5. حق الانسحاب</h2>
<p>نظراً لطبيعة المنتجات الغذائية، لا يمكن ممارسة حق الانسحاب.</p>

<h2>6. الدفع</h2>
<p>يتم الدفع باستخدام الطريقة المختارة أثناء الطلب (بطاقة ائتمان، نقداً، إلخ).</p>

<h2>7. حل النزاعات</h2>
<p>تختص لجان تحكيم المستهلك ومحاكم المستهلك بالنزاعات الناشئة عن هذه الاتفاقية.</p>',
GETUTCDATE(), GETUTCDATE());

-- Başarı mesajı
SELECT N'Yasal belgeler başarıyla eklendi!' AS Message;
SELECT COUNT(*) AS TotalDocuments FROM LegalDocuments;
