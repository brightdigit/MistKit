<!--
Downloaded via https://llm.codes by @steipete on October 20, 2025 at 04:09 PM
Source URL: https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html
Total pages processed: 30
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html

CloudKit Web Services Reference

## About CloudKit Web Services

You use the CloudKit native framework to take your app’s existing data and store it in the cloud so that the user can access it on multiple devices. Then you can use CloudKit web services or CloudKit JS to provide a web interface for users to access the same data as your app. To use CloudKit web services, you must have the schema for your databases already created. CloudKit web services provides an HTTP interface to fetch, create, update, and delete records, zones, and subscriptions. You also have access to discoverable users and contacts. Alternatively, you can use the JavaScript API to access these services from a web app.

This document assumes that you are already familiar with CloudKit and CloudKit Dashboard. The following resources provide more information about CloudKit:

- _CloudKit Quick Start_ and _CloudKit Framework Reference_ teach you how to create a CloudKit app and use CloudKit Dashboard.

- _CloudKit JavaScript Reference_ describes an alternative JavaScript API for accessing your app’s CloudKit databases from a web app.

- _CloudKit Catalog: An Introduction to CloudKit (Cocoa and JavaScript)_ sample code demonstrates CloudKit web services and CloudKit JS. For the interactive hosted version of this sample, go to CloudKit Catalog.

- _iCloud Design Guide_ provides an overview of all the iCloud services available to apps submitted to the store.

Composing Web Service Requests

[](http://www.apple.com/legal/terms/site.html) \|
[](http://www.apple.com/privacy/) \|
Updated: 2016-06-13

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Art/webservices_intro_2x.png

�PNG


ޤA�פ��T�o�xR�}x���A�\\�n��'��B^���t"��5��mgIRH�Ho��@������o �-.��e�.A��NZ d�$��
��A��N�5�\`I���O'�SX�G�cM�+C�, �$�9��0�O� B!EmO�������t
"�V A�IA�IA�&A�&A�DA�DDr!�% �������Ƿ֒&�l��N�o�j�ud5�n1;�~o�\\��s��$������"���阌�.�}��ྑ&�t�ނ�&u(�����U5�\|7����d�\]����\|7��������s�:���3H��r:�I1�0�m�{�萖�����á�&���8�ٔ7�B�$� � �$� H�� H�� M"� M"�4� �4� �$� �$� H�� H�� M"� M"� M"���nO����I�40�d�J�S!M"���&�Z�r�iA$��&�b�7����\_mV�$� fH�x\`�~}���8���?��D���j"�Uv�\_���kN�e38�ͤ�&1mr4:��\_-����z6�p�3��K�DĴ�Q�z�GB�πFd�z�E̀8\\���4� �^Կ����?@Ї^d§J0p�^������d��7�HX����l���S@�O���̀��cL�ӥ%�uQ:��2\|���

��f�� JO��0qd-!���g�m �\_\*��(��p�{X��O�NpM�t�� (� ��\\�e�����n�6"X���B�D$&\*���T2vq+�ٙ%g��2���L�c�L�T�֤�s�

���^�h�՗�w�m@�������N$k��J��p��b,������N�NTM�=�������\
Y�<�D/h&��q/�ۋ�/x�����8�X��Ql<��Cx�T�TF�4��������\*x�Uh��\]�"�,�I�������j��r"�h�����r��D�. h�+��s���tw��9g��\\���s;dpp���9�9ؽpp�nίVxѿS��๟�vN$��Ԥ�����AE(Qj�
H��r'�&}:K�����f��E��g���q�{\\��3wG�ą��0$rp�I{��:� 0�h{�vn���C�XJ,�� �Yߟ��%�&}2�Ok���z��zp���B6 1������k�@�D$\|S���=(�

&H\_��&�� X�X�S���?��(��㫷�7�5��M�4������\[�1�HP@s"\
�������)́+�4h.���D�H��\]g�<�J%�\`14��?��}";o �IO�\*�"@�������)(あ��Q\|����\\��&\*R���<
Y(Q�HC��fve9�o҂��C�㵫�$�HM����v��f)�{e%��H
�O�ͤ,�b<��
~��,J���܉D\`�CnZ~��X0MB ��:si:��
��ʝ\`��.�i���r�nR8�.�0X�µ�ܴý�܉D��Ȫ����5��,���r8�%�RB�r'�&�wi�d�ܙlPp.h4iah�f��Ҵm�(��Q�4)�Z;�T9�\]6���)\*�P��7r�g��8�;�4��y n9Cc����ĳ�����

������\[����()5��;�T�d\]iVW���WR����f܃V�+�iK��N��o��4ٛ�Ѕ��N���۶.fj}�ȷ��c@�2����U�y�����h�/�?�^���?��{F}��+S�V��,��
^�7�9�N;�� �ʝ@�d3���罪ےg���6��

����BD���������? ���!U���<Ѱc��q�����\_��@J�����@: ��o���\*.�%+���\_v��ı�� �j

�V<�5���e@�\`?�& �����{��6̘�CQ�2�� ����O0�KR���#Y��w�b�3w\|�}چy��s�J"�2OM�/�eIޡ��K���K��$���\_�?O\[���83���I���^×�!j'P�\`. A�%4G}ÿ�b�\
� ��96�sp� �Hܘ��cRYVfffff�{�B�fw���!3;N��ث�����X�3��s�k(�;�4����3�+�am��7�o��Ĭo��mH�\]/%�\

�m�A��iL0� N�s���MIʔ�H�:�q�/\|3�r��RlDI;���,\

�ˡ5��\
<��c���c�+1s�;� �A:�07l�^+��~Y�q���J����?�jRs��f%��⃚�9l%a�$;-�6�1�FcJ1%��.�\
�-�T��ց�W��T���K������������?y/��M�k�1�z\[���\_����\
�ű�$\|T�NRS���ϋ��ق\

���Ty�;�8�T�dLfBkU�FU4)s�\|�F�HH��!�a���)y�x�k����\\�\\����˪:�׹~�j��?�\]J��Î7����SKN�~ܟ����U�I��%,O�;�7.�p��E��z \_�}�dd�WX���ATaP u8\
�\_w�T&A�\]�t� ���ܽ+/�\
�~@�sp�n��o��cw\_=����v�\
%���y�:o a'�S93}$�g��e<���=e�B��q\\���3�g�4��ˣ3�\\�1u�L��ְNP�R34Khۚ�mk�\
��X��u3^�'IN�-Ou��fE��&�e��h���ԓ�i���~���w{+��\[~E�L#M����U�\_b���^�)U6\\%������~���8���Of�I�5)������\|?���B�� @=�\
@�s��bRIwR3פ:&�����C�j�˵��i�;���ޛ�󝏻�\[����C�;<�a����Ĕ\|�:F�^�����ؑ~��6L�\_JS��⨠2(�Ų���A3�\
q((G�W���<^� �'W��\
"���c2�'&F�W�=e�wf.��L�����\_a}��a2œb˹NQEQ�{��y�\

H;�a��Kƙ��jyu�~�����\`y��y�Qo(�\_�r\],��6b����8�\_�CUd�j��O/0��㭎�$Hؿ����JRw���rm�ނ��$�����AU��~9��UN�B�S�������$�Rc"J�!y=���2�UVx\[r��l�h����ټ��m���c߮fwd�!��g4�M�%�Y"�}7��3�B�������d�-h~�셰xg�����9.v@JWLv�va��sP�fG˯�Zl��eI��N�Â'ƅt�,��%�M�W�jf���ج�ۿ+{���$�&�;�\`n\_�N�+@W��O� �t-\
�1��9�-��8VR�/����\
���S�B���(\[X�����Js�����P wdT��Q$�/\\I����������<���$��vh�Ks~�;��8������\\���k�CfA6𢜚�Y���Ƞ�~\

,j�q3iȗL��t��z�1����J�\
Akn\
Z��%�����rV={�N)��{�9�Z����ZK�-�T4��9W\`����u���K9�52\`X��?��#�D��hҭo��7Gm�g@C��uv6��ܢ���4\
�ΏT-�\*��;��3l�R,i�h��q��!Y�;r�G%�淃K88B���u$\_P9��f�-=���X���\*qv���+��-��ZT��o�-h������Czl)�\`�KŒf�&=^��P�p� ׍��/}ye�zA��;,�m �?ç��4��G��Y�+#\
j�(�VX2�aЬ�PlB�ǾѰ������\\�H\[��bI�H��<\[\`!�s+�&t���U/\

~W\`��85w�\\�T:2�8�e�"h��I,I����6Y��s�F䱤����B�QњѤ���E���meG��΍���Òd��I~nQx��=g��;��\|ѹE+g���:'�٦��\`CO��'��YǼ)Y:��$�yZD��4�p-;Yiǐ+ص���vLı��Ҹ�C�c�M�f�+C�e/X�ZӶUJڕ��܄3����\|��Ȇ�,:c(k�v8���ӗ9��0�\[�i�;:�Q\`�0��e\_�\]BIyK~�?��v��r�\
/���M��$�=�d�HK;�^%��8yX��n�5R��\`�Wc��5�����#F�F�E�a0YۉC�U4V��C���o���Y��-M�glW�P�h8�Zz��\|�\_}5�֜6��zI���W $������,�c�axH����bJ�I!ǻ�,?��"cL;U���E����WL����+�i���'��7䭈�yIy�Z��W�'M�\
8�@\]����݅��<�ȉw�V�,�f�,�4 �j䀱����;��g�n�d�H��{V�%�P�@\*�?̼&�.u\|g��:P��Z�m�bG��p�H��E),��Z�������r�c-kM��L�I�˟m�x� ;\`p������0&�&a�g\\����7��C8�\`.;���v��g0?k�M���6<n4�r�\_P\]7�k�k���W���Y�q&�ҸY1���rH 6n�ǫ+I�aK��noN@Az��{�f�gL�l\_o���~���{"�<٫횶�k�8Ӵ�V�&����"���Z�H�W#� &��k���(@��Á۝8�C�������z�a���6F=K��U��V��Z\
��\[\] X�C�,D;���!��mQMӒ��&���X��\[���5r�)c�1ͱ8�X;\\a�n@O�= �I;̺9���D�4ij����\*I+�:�\`Y��!�V&�5�W�5-�\_���\
O���o��I�Z���i�45�I&H�E����&+�Ke����j�;��e�#��h�x���Tɳ���FH��\
<U��\*H��p7��b2�\]r���g�ԅ^�\
A�Q��$7�$�\]$d'M�{�Ѭ@��W\`��#�\

T7O�"�0�b�:f��=R��� �1=}f�+դd'E��e�� R���i��QK㲘Dp�Ϭ���ٝj�G���Z�ޡઔ@4f�,4=\`�G?nI�)N�6<�2��G!v̅��f��\`f7��A�8��'e��{=É�r����c�S�ث�H\]��zkӓ!�Kg~f��$��b×�˖�98��\`\|U��\_���ɔM�bƏ�\\9�會�ee=M�G\`˕�c(U�l�΄?��n\]I�P�I11�۳l뀗��񡻽0��\`�f���)�Sz�U�%9�$i���IS=!VsK�mO��)pqI:C���&!�c��^���%�֜b��F\|R?��������S�PiK��ȩ�;5QG�h�m�k�re5 �ɣ��G��xڷ\|f����$ا�4��Ԅ}����PB������S���#��%���V��i���<�T�%�3��<�w2H�f�&�V�x�}LU�/�,+��UG\

��~R\[ƌF�S&��\
�@�D���� �s�d\`�D�Mt�"ܤI�,�n���\\0S�d�h&ɏ�$%(4����j����\

$IQ��iC���$�i8�����A�.H���DL=tS�\
��#��2j�4H�mv�m�\[���S�W�f��?;�g��)��9�M�$E����0\_�ri��\

S%��\`��Bk�\*�o�-E�bA�&A�םݍn�r�l��W������z(��~�kӭI+O�͚��b��\]Qj4�U��b��W���!�&\]��nLtɔ@��Zv�c����:n+15�\_��&���v�v�r,���a���p&�5\_/�t;ݚ7�M+ݙ(r��-����﹤\
���Ү��� ����\*\
Pź��w�i�vM"��%Qj^{FDcx��!f�^�~wPujh\
ݛ(�蚠犆%�<u��b\

Tҝ\

s�i�g�G����F��!� �7�M< w�5g�艒�Q6�˛ԯy\*�Nx8\[h\
~+7 �� ����{�X����\]e�#�o�V�Gh.��7��j\[7e;� &I-�g)e\\7ݑwvr��u�ω�a�������D��uf��#ݶ��e��A�\]�J =�,�d��"��텋���ұ}\_mw�����~��iR�%z�fAM��޺ۭ�-t?�@��2�-������n�@���o�{��7��9����.��\
��a�'L�i�e��\\0����#��C0�/���+��=��������u\
�%��h�ʆ%�k\_kR���GQ��(�c���=A\|�����Kw�l����w�4V�ԭ@Z�m�sO\]�߰Ҏ��3��A6��D%��\|��d��X&������¨̐� \*ua�Z���@a��E\_��au�ڷ�ۦ��l��e���x�\\Y�׀r��r��Q�$��,5�s�-%�ٽ�ն�w��:�\\���3�M���%��µ�9\\���לH������c� A�i8������l�4�/���׵�Y� \`p��,\

h�^��̱/���\*3�g�'a�,�4��Bi��\\��BQ�޻���S$��<�Jt���I�j�V� b\*��̕)�4Mq c�n�������#�h�ϛ���H�\|����W\\\ݼQE� ʑּ̰������WVIP<��I��"��.Q�^~7���0�!��W;~m{e£-VX}&o�ҁ�Π���j�P\|�!����̕�ꧫ#���!s\`u��g���e�E�����W~udx�9�@�r&�̥�j�iHM�������\_���;��C�Նr X��Ws��nR'x.Y�n-K���1�\]S�j��pJQ\\�1�u��R o�\[${pTj.\]0�<���o�����N�;��H�0ä&� �\[�/J��gjwM��MG�C�4�u}f�Z���m�j.h-��K��r9g�zX'Nq�5�m$�.�&���n���}mH~�~�þ$�r����'}��G�=.�"ۨ���4��B�^�Gн��~n�����\*\

O%�$���<;�6=$���W�L�uS���V�����c�1\

����\_\]�fqR�T�\\�Q&�\[����mU\|��U��K��/-pM��%z� ;�C��o-\
�1�X�v�������l\]s�@��j,���\

�߫'\]6\`�~ù�\_n��D��<�;9?JbcB\_w-P�ک�O�vdp�w��"0��5��n'�%#��ٗV�k\]����q{L<������\`���"��֘��w�U��v�Ls��{"��}�p�$\_$�;#\`Kas4�'w���7�;k��8j�((Ҩ�lV\_y�T9���7D2шӣM�Ǿ�Kx̗P�F�%��Ԏ�4��%iu�u�d4@����M��c�6�B�k/�g��)ǔ�\\"L2f�\`�0�ٚZ��ձ��V���Z7O㝩RC.İ7�a���\*5��7G�q��B���)v8
��1�Z���y��zy3��++&S��1�!BN\]��;��BN�T�q��xmj������N?�h�F!��\[�^��Ɣ�Q�̳�!i62���7�ZveD�\|yJ�IU��1ţ�xc�:�ޛ\*��h&�dn�LÃalS�1\`���M��sG�A4�I����;�Uu�4M�KF��+c6�x�F��\*=S��ge���A��}��u�������;j�3-O=��?�$ߍ�vj:��u����j\`��4�@�N6 s-������ɕy�iR�vژ�Dᾙ���k,p䰉!8f\
Y�d$h�I�"ԟ���{�@��%ǰ$���x<�����I����/\\��e��Tc� saV�X����R���'�C�U<�0W���rm���x���Q-M�}���&#��\_����z9{�I�Я�@�M"�q$�ܳ�I����j��p\\w8�?T���RG��6�5/�\\�.:"�=���6��I�xUWS�!�o)�9c�}����\*a����\
G����n�~n�ed i1���@�?G��W�0�=��p7���� L����H)3IR-b���t��#a��ڧh��P@���8+�g��4C��\

��'���cE{�I)S#��mg�3E�Eq���I��o�\[��~8�MN�K��i�8H�2p�O�� �\`\_�����n�60Q��?�<~��~Y4��AĆ��2�}v�a�\]��m�D���
RX@Lj��V�g���c\_e����3�%I�<�H8�0Is����DO�������W�3g��A�z࿾3q���uÿ�(i3lw6M�P��'J�w�d�\[}y�{�HD�w�r�+��c���I5�\
ƙ�v\]~GU\]4�D�;��i�
(�Od�U�R�\`����CE\_�\]����X�7�^�����,�$b��j����e�
o�g�dw�:�w�D�yϵͺ˥M�i�M�PC�$c���ġ�6L���3�{\[D��"s�G�����}�RF��\\�\`Y�)\`��ݞ�~��\_��'΢�'��ID��͑�\

iS���D�����Sf���\*�l񫥤���$ �������?8���w���v��u\*�,u1��zXgC3��c;�0k�o��0~��A�o�\`4�;��^����܏��R�9�H�o�J&

���i���&M����t�GI��L��ù��K\_���.1Џl��A�DLw���$\]p�zo��!!�37�V���t��y$k�R�fq������R� ߍ�fN�������OY"�������%������s�)�� �$Y��N�4��nI\
c���O:��J�nX���Z�lb��}���њ�P���\
)�)�T��^�vx��s���6�nĴ7�P�T�W�����o�JhK�Kw��4�� ��'�x\
5��Y��T0\\qL����:���5s5��h��$�$b�������鼼���:/�oid&u��sGJ �����tF��a�������\`1������Q�F�����#�����䛤ID8\\�˂Ã�'�3�A�4��������g�ٲkb���F�o~��k��ܢ�#�s/g@���i���}WI����R��m���A7.G�����W\_���4:w���%ƻVjzT�ln�\]���D����Q��������֙3�KN����\`p?�� IǬ�ܞP�;2F�q;D�ᷔ6\\��ya6gPR�7�}IR�F,IXk�y�.��&��MS�&�a�km� o����$�Ox\*�b���\|�&w����H�D�Ru���r;��=���t-اi��BM���9����Č�f}��J�\[�9��\[Z\
�ȹ૟��c�ID(~�\[��������P�Z�1��N�&D��5Q=y}I���ߏx�C(\]\]s�mn\]
��

\\\[g�i�l=3i�x�{�zYIIZ��5��}\[�f���� �0���u� k��Z�,�,{�f�"CPa�W�$"8\

�h.k.��8Z���\\��e�e��N"M"��\_�+���Lj�\\k\*��\\�⮌ʱ˷��M-���\

��c~2�w\
g�=��k�k r=5��bܳ��;&?teb����l���c��3}Tǃß��:V��� �IĴ����Ī"��S���Aj�fc�$1}t�\[k9od'3��w&.���v �ãz���\`\
N��v�\\���6f֤�$�������;�&gJ�z�����\
Sݓ��p��e���o�5�:���c�8H��IČaO��7u~�a�\

�&��E!��Zi����5��:������{��HJ�vd���n}x��\|�=c4��/�@7i����;!V���xuU2NC��9#e���bd {�/�P���/�\_�\[b-�RJ\
+�\
�\*C�+�N9��ۦs�W({}(���3�3 �r�xo�n�^4 �s#��'ﮤ�������+�צG���mz��+�N9��A���$��Z�ħ��{調��x�����l-�66��w��a���\[V��f�$��;:��I�ӯ��{��=zk�F�\
����a%z\

XU��)����ThCQ��Q\]�唫{��ɖ���Q\]j\

O ����F��� &�e��j����@��b�������n5-aǛ�&%�\]��\
l<��@�d���)2ðfI\`M2�'���4qI�؜펔�Ko�W\]"MJ&��O\\5&}��\
�S���Ol���ӎ7\
h' ���n?�e��ec�H����Q7/\`sķE�d��S'Gvk\[�Ré��e&��v��������m���o�nn���nS���է�g��w+&MJ&�����8�GO��o�ie���B�֭z�P�=��y�2�s\|x�������˺i��1�\*��Z?��9Z\|�b�ݒ��)����mN\_���ԇ���\_�/zZ��Ė^�xz�\
��^z�$��k�:����eO\\�n�)�&3\
�G���)�ݴ@cp�i�h�p:s\`o�V�:m\`��vh\*�����ڰ��;��њk�5\
/j���\|��to�ٟ�B�Μ�1��'TJ�I�l���۳f��{�;t���yɁ�\\�RU\

���%��F��Y����9\*C9WN�4K��W����x8��kR��������l�J=���j������i$R��������UG��\
���k����d��Z����5S�'�/a��7g���4z�� 1<۟��\

6��Y�����h�Z�ö��Y�h}W�7/�'㝗��y���?�MX���������Ѥ�75M����򓫣^B$�I�f��K�"���.�j"�6Y����L�nn.��QS<)��Y���Q�Q������-�6Z��S���'l�0F�u\*U:��4�4\
P�溵I�Xϼ\\7к�i��%��^Ț�CZ}qÔ���s��1��#���\_7�C3����(��3�D�k��q�?�vN��᝷�C��LҤ$D�&2���\
aAl�yχ�l9�����@�\
�@���aZ�q�X�M��7�)ܘ��\
ē٤ID@��ʙe�g���%\\Z5}��w���5��(kR�΋\`q�4�U����8U��O�x��4���,�g��\*��S/�ѹ�\_Z��Ԩ�ܸ,�&�Ңz�M)aګ�F�O���S�˲B��(e��&%#=z��y&E���m7�7Ŧ���6o\[�7�c���7���hV�Uk#\[��\*+���Җ <�(\

�����K�y���o�=��V�.�\_�.\_�� �E�uv^f�t~ɀ��ZF���{o?���GG�+O����G%I^�9j!\]�g� �DZ�(.(t��6gt�a0Z?G�w��\\{���/ln���+��X��?�Ůύ����\]�&�3̣K�?�V�Rz���#��:�۞;F��G�,��E8��t=�D�,����f���&8e����\

�M��81O�����c$I�m'������ztT�FY}G\[^�ˣ!�?ti�{�R�R�x��#M���?p���ZUB�R���CT���eo�Suc=�ݝ��F��l1�7�D����$5X��@��^�:\|e1��$�)��?euPQ�i�7l)���o�\`�ڶaN����������/=\
S��\\��.�}z}5h'��%9�v�J9��xJſM�'��}n��\
\[�����\\��4�\]$IJ7I�'�\_LO7������������!8�I�N�S���o�I�Y�K?V�����u����S��vi�ʩw��O��Ă���F��6Zy;�c�?Z��&%=�������<���$���&�o��BǊ\_�:�A�Jb�nϼe�)�mG?���\|����\
'�\_�����7�܎�I�������l���'����LyɻW�?4��e��X\_a��\

����s��\[SN�����4/I,u�q~���/.s\\�iC�\*!;i6����\`�Fh'����\*\`�� {����ؼ�I����u������{.sy����u��ԘR�T���$U����8������ȷ�9�)���N�d�}!��W�1��n�m���xn�Nu��w���VO��=u3�n�8\|�D��B�IB��?��x�)�����c��Av1��'�)\]����r;�'�\
��2�Bϒ\*�2�/�19�-�,�$m~\*��$���P4l&MJ&�~�/�':"���q���^ܔ�S}�Dv#\]��ؚs��Z\
�O<�l���l�O�N�\

�u���{�� ޲�DȾ��U,Xٿ&�<�J�����M�ů)�C+�\
�Kk���N�qe�ݬ����(�#��O�=�����"Ć%�1U2P<)w����4WP!j�v�������ƢS\`��I���J�FW!,\|+���O���\|7�\\t�.^tc\
\|a���MҤ�DOW\]���+I5��1���R��r֢tE��2 �!M�UT�v��\]<\]I��66z��q��B�F '���\`Y����H�C�I��S�x�\*D���"�Ni���Ox����\
�Ύޓ����E�4i�Q�y�f�\
��ۥ&\]m�1:tq���T��c�\[�F���X��&�M%��U�\

�Q���\|�.�\[B����sE��?X1�폥Z�wјE.�dQ\
��I�RAvADi�x<'�Ĥ)/'U�vu�$�� <pv�D�\]2��� f9\

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/Introduction/Introduction.html

Documentation Archive Developer

Search

Search Documentation Archive

Next

# About This Document

This document gets you started creating a CloudKit app that stores structured app and user data in iCloud. Using CloudKit, instances of your app—launched by different users on different devices—have access to the records stored in the app’s database. Use CloudKit if you have model objects that you want to persist and share between multiple apps running on multiple devices. These model objects are stored as records in the database and can be provided by you or authored by the user.

You’ll learn how to:

- Enable CloudKit in your Xcode project and create a schema programmatically or with CloudKit Dashboard

- Fetch records and subscribe to changes in your code

- Use field types that are optimized for large data files and location data

- Subscribe to record changes to improve performance

- Test your CloudKit app on multiple devices before uploading it to the App Store, Mac App Store, or Apple TV App Store.

- Deploy the schema to production and keep it current with each release of your app

See Glossary for the definition of database terms used in this book.

## See Also

The following WWDC sessions provide more CloudKit architecture and API details:

- WWDC 2014: Introducing CloudKit introduces the basic architecture and APIs used to save and fetch records.

- WWDC 2014: Advanced CloudKit covers topics such as private data, custom record zones, ensuring data integrity, and effectively modeling your data.

- WWDC 2015: CloudKit Tips and Tricks explore some of its lesser-known features and best practices for subscriptions and queries.

- WWDC 2016: What's New with CloudKit covers the new sharing APIs that lets you share private data between iCloud users.

- WWDC 2016: CloudKit Best Practices best practices from the CloudKit engineering team about how to take advantage of the APIs and push notifications in order to provide your users with the best experience.

The following documents describe web app APIs you can use to access the same data as your native app:

- _CloudKit JS Reference_ describes the JavaScript library you can use to access data from a web app.

- _CloudKit Web Services Reference_ describes equivalent web services requests that you can use to access data from a web app.

The following documents provide more information about related topics:

- Designing for CloudKit in _iCloud Design Guide_ provides an overview of CloudKit.

- _App Distribution Quick Start_ teaches you how to provision your app for development and run your app on devices.

- _App Distribution Guide_ contains all the provisioning steps including configuring app services and submitting your app to the store.

- _Start Developing iOS Apps (Swift)_ introduces you to Xcode and the steps to create a basic iOS app.

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2017-09-19

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/Introduction.html

Documentation Archive Developer

Search

Search Documentation Archive

Next

# About Incorporating iCloud into Your App

iCloud is a free service that lets users access their personal content on all their devices—wirelessly and automatically via Apple ID. iCloud does this by combining network-based storage with dedicated APIs, supported by full integration with the operating system. Apple provides server infrastructure, backup, and user accounts, so you can focus on building great iCloud-enabled apps.

There are three iCloud storage services: key-value storage, document storage, and CloudKit. The core idea behind key-value and document storage is to eliminate explicit synchronization between devices. A user never needs to think about syncing, and your app never interacts directly with iCloud servers. When you adopt these APIs as described in this document, changes appear automatically on all the devices attached to an iCloud account. Your users get safe, consistent, and transparent access to their personal content everywhere.

CloudKit allows you to store app and user data as records in a public database, that is shared between users of your app, or a private database accessible only by the current user. However, it’s your responsibility to determine when to fetch and save records. Because the data is shared, your app also needs to keep local records synchronized. For native apps, CloudKit provides the CloudKit framework, and for web apps, the CloudKit JS library and web services to access these databases.

To check the availability of iCloud services for your type of app, see Supported Capabilities in _App Distribution Guide_.

## At a Glance

iCloud is all about content, so your integration effort focuses on the model layer of your app. Because instances of your app running on a user’s other devices can change the local app instance’s data model, you design your app to handle such changes. You might also need to modify the user interface for presenting iCloud-based files and data.

In one important case, Cocoa adopts iCloud for you: A document-based app for OS X v10.8 or later requires very little iCloud adoption work, thanks to the capabilities of the `NSDocument` class.

There are many different ways you can use iCloud storage, and a variety of technologies available to access it. This document introduces all the iCloud storage APIs and offers guidance in how to design your app in the context of iCloud.

### iCloud Supports User Workflows

Adopting iCloud key-value and document storage in your app lets your users begin a workflow on one device and finish it on another.

Say you provide a podcast app. A commuter subscribes to a podcast on his iPhone and listens to the first 20 minutes on his way to work. At the office, he launches your app on his iPad. The episode automatically downloads and the play head advances to the point he was listening to.

For a drawing app, an architect creates some sketches on her iPad while visiting a client. On returning to her studio, she launches your app on her iMac. All the new sketches are already there, waiting to be opened and worked on.

To store state information for the podcast app in iCloud, you’d use iCloud key-value storage. To store the architectural drawings in iCloud, you’d use iCloud document storage.

### Many Kinds of iCloud Storage

There are four iCloud storage APIs to choose from. To pick the right one (or combination) for your app, make sure you understand the purpose and capabilities of each. The iCloud storage types are:

- **Key-value storage** for discrete values, such as preferences, settings, and simple app state.

- **iCloud document storage** for user-visible file-based information such as word-processing documents, drawings, and complex app state.

- _Core Data storage_ for shoebox-style apps and server-based, multidevice database solutions for structured content. iCloud Core Data storage is built on iCloud document storage and employs the same iCloud APIs.

- _CloudKit storage_ for managing structured data in iCloud yourself and for sharing data among all of your users.

## See Also

This guide assumes you are already familiar with the software and tools you use to write code. If not, start by reading a number of platform-specific tutorials. Next, read the technology overview documents and then the specific iCloud technology documents.

| | iOS, tvOS | Mac |
| --- | --- | --- |

| To learn about iCloud key-value storage | _NSUbiquitousKeyValueStore Class Reference_ | _NSUbiquitousKeyValueStore Class Reference_ |
| To learn about iCloud document storage | _Document-Based App Programming Guide for iOS_ | _Document-Based App Programming Guide for Mac_ |

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2015-12-17

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html

CloudKit Web Services Reference

On This Page

- The Web Service URL
- Accessing CloudKit Using an API Token
- Accessing CloudKit Using a Server-to-Server Key

## Composing Web Service Requests

CloudKit web service URLs have common components. Always begin the endpoints with the CloudKit web service path followed by `database`, the protocol version number, container ID, and environment. Then pass the operation subpath containing the credentials to access CloudKit using either an API Token or server-to-server key.

Use an API Token from a website or an embedded web view in a native app, or when you need to authenticate the user, described in Accessing CloudKit Using an API Token. If the request requires user authentication, use the information in the response to authenticate the user. Use a server-to-server key to access the public database from a server process or script, described in Accessing CloudKit Using a Server-to-Server Key.

Read the following chapters for the operation-specific JSON request and response dictionaries associated with each web service call.

### The Web Service URL

This is the path and common parameters used in all the CloudKit web service URLs:

`[path]/database/[version]/[container]/[environment]/[operation-specific subpath]`

_path_

The URL to the CloudKit web service, which is `https://api.apple-cloudkit.com`.

_version_

The protocol version—currently, 1.

_container_

A unique identifier for the app’s container. The container ID begins with `iCloud.`.

_environment_

The version of the app’s container. Pass `development` to use the environment that is not accessible by apps available on the store. Pass `production` to use the environment that is accessible by development apps and apps available on the store.

_operation-specific subpath_

The operation-specific subpath (provided in the following chapters).

### Accessing CloudKit Using an API Token

To access a container as a user, append this subpath to the end of the web service URL. Provide an API token you created using CloudKit Dashboard and optionally, a web token to authenticate the user.

1. `?ckAPIToken=[API token]&ckWebAuthToken=[Web Auth Token]`

_API token_

An API token allowing access to the container. The `ckAPIToken` key is required.

To create an API token, read Creating an API Token.

_Web Auth Token_

The identifier of an authenticated user. The `ckWebAuthToken` key is optional, but if omitted and required, the request fails.

To authenticate the user and retrieve this token, read Getting the Web Authentication Token.

### Creating an API Token

Use CloudKit Dashboard to create the API token.

**To create an API token**

01. Sign in to CloudKit Dashboard.

02. In the upper left, from the pop-up menu, choose the container used by your app.

API tokens are associated with a container.

03. In the left column, click API Access.

04. In the heading of the second column, choose API Tokens from the pop-up menu.

05. Click the Add button (+) in the upper-left corner of the detail area.

06. Enter a name for the API token.

!image: ../Art/1_create_api_token.pdf
07. (Optional) Specify a custom URL that is loaded after the user signs in using his or her Apple ID.

In the Sign In Callback field, choose `http://` and enter a custom URL.

08. (Optional) Restrict the domains that can access your app’s container using CloudKit web services.

In the Allowed Origins field, choose "Specific domains” and enter a domain.

09. (Optional) Enter a description in the Notes field.

10. Click Save.

### Use and Duration of the Web Authentication Token

Each token is intended for a single round trip to the server. Whenever a token is sent to the server, a new token is provided in the response from the server. Once the response is received, the previous token is no longer valid. It must be discarded and the new, returned token used in the next request.

By default, the web authentication token expires 30 minutes after it is created. If the user selects “Keep me signed in” during the sign-in window, the duration of the token is 2 weeks.

### Getting the Web Authentication Token

Some database operations require that users sign in using their Apple ID. Your web app will need to handle these authentication errors and present the user with a dialog to sign in. Apple will present the actual sign-in page through a redirect URL so that the user’s credentials remain confidential. If the user chooses to sign in, the response contains a web authentication token that you use in the subpath of subsequent requests.

**To authenticate a user**

1. Send a request (specifying the API token in the subpath) that requires a user to sign in.

An `AUTHENTICATION_REQUIRED` error occurs, and the response contains a redirect URL.

For example, send a request to get the current user, and append the API token.

1. `curl "https://api.apple-cloudkit.com/database/1/[container]/[environment]/[database]/users/current?ckAPIToken=[API token]"`

The response contains a dictionary similar to this one:

1. `{`
2. ` "uuid":"4f02f7aa-fbb5-4cf8ae8e-4dd463793841",`
3. ` "serverErrorCode":"AUTHENTICATION_REQUIRED",`
4. ` "reason":"request needs authorization",`
5. ` "redirectURL":"[redirect URL]"`
6. `}`

2. If you did not specify a custom URL when creating the API token, register an event listener with the window object to be notified when the user signs in.

1. `window.addEventListener('message', function(e) {`
2. ` console.log(e.data.ckWebAuthToken);`
3. `})`

3. Open the value for the `redirectURL` key that you received in the response.

The Apple sign-in dialog appears displaying your app icon and name. If the user enters the Apple ID and password, the response contains a `ckWebAuthToken` string. If you specified a custom URL when creating the API token, the `ckWebAuthToken` string is passed to the custom URL, as in `https://[my-callback-url]/?ckWebAuthToken=[Web Auth Token]`.

4. Encode and append the `ckWebAuthToken` string that you received to future requests.

To URL encode the `ckWebAuthToken` string, replace '+' with '%2B', '/' with '%2F', and '=' with '%3D'. For example, send a request to get the current user by appending the `ckWebAuthToken` string.

1. `curl "https://api.apple-cloudkit.com/database/1/[container]/[environment]/[database]/users/current?ckAPIToken=[API token]&ckWebAuthToken=[Web Auth Token]"`

The request succeeds and the response contains the `userRecordName` key, described in Fetching Current User (users/current).

### Accessing CloudKit Using a Server-to-Server Key

Use a server-to-server key to access the public database of a container as the developer who created the key. You create the server-to-server certificate (that includes the private and public key) locally. Then use CloudKit Dashboard to enter the public key and create a key ID that you include in the subpath of your web services requests.

See _CloudKit Catalog: An Introduction to CloudKit (Cocoa and JavaScript)_ for a JavaScript sample that uses a server-to-server key.

### Creating a Server-to-Server Certificate

You create the certificate, containing the private and public key, on your Mac. The certificate never expires but you can revoke it.

**To create a server-to-server certificate**

1. Launch Terminal.

2. Enter this command:

1. `openssl ecparam -name prime256v1 -genkey -noout -out eckey.pem`

A `eckey.pem` file appears in the current folder.

You’ll need the public key from the certificate to enter in CloudKit Dashboard later.

**To get the public key for a server-to-server certificate**

1. In Terminal, enter this command:

1. `openssl ec -in eckey.pem -pubout`

The public key appears in the output.

1. `read EC key`
2. `writing EC key`
3. `-----BEGIN PUBLIC KEY-----`
4. `MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAExnKj6w8e3pxjtaOUfaNNjsnXHgWH`
5. `nQA3TzMT5P32tK8PjLHzpPm6doaDvGKZcS99YAXjO+u5pe9PtsmBKWTuWA==`
6. `-----END PUBLIC KEY-----`

### Storing the Server-to-Server Public Key and Getting the Key Identifier

To enable server-to-server API access, enter the public key in CloudKit Dashboard. Later, you’ll use the key ID generated by CloudKit Dashboard in the subpath of your web services requests.

**To add a server-to-server key to the container**

1. Sign in to CloudKit Dashboard.

2. In the upper left, from the pop-up menu, choose the container used by your app.

3. In the left column, click API Access.

4. In the heading of the second column, choose Server-to-Server Keys from the pop-up menu.

5. Click the Add button (+) in the upper-left corner of the detail area.

6. Enter the public key for the server-to-server key that you created in Creating a Server-to-Server Certificate.

7. (Optional) Enter notes.

8. Click Save.

Use the identifier that appears in the Key ID field in your requests. If you are using web services, pass the key ID as the `X-Apple-CloudKit-Request-KeyID` property in the header of your signed requests, described in Authenticate Web Service Requests. If you are using CloudKit JS, set the `serverToServerKeyAuth.keyID` field in the `CloudKit.ContainerConfig` structure to the key ID.

### Authenticate Web Service Requests

When using a server-to-server key, you sign the web service request.

**To create a signed request using the server-to-server certificate in your keychain**

1. Concatenate the following parameters and separate them with colons.

1. `[Current date]:[Request body]:[Web service URL subpath]`

_Current date_

The ISO8601 representation of the current date (without milliseconds)—for example, `2016-01-25T22:15:43Z`.

_Request body_

The base64 string encoded SHA-256 hash of the body.

_Web service URL subpath_

The URL described in The Web Service URL but without the `[path]` component, as in:

1. `/database/1/iCloud.com.example.gkumar.MyApp/development/public/records/query`

2. Compute the ECDSA signature of this message with your private key.

3. Add the following request headers.

1. `X-Apple-CloudKit-Request-KeyID: [keyID]`
2. `X-Apple-CloudKit-Request-ISO8601Date: [date]`
3. `X-Apple-CloudKit-Request-SignatureV1: [signature]`

_keyID_

The identifier for the server-to-server key obtained from CloudKit Dashboard, described in Storing the Server-to-Server Public Key and Getting the Key Identifier.

_date_

The ISO8601 representation of the current date (without milliseconds).

_signature_

The signature created in Step 2.

For example, this `curl` command creates a signed request to lookup email addresses.

1. `curl -X POST -H "content-type: text/plain" -H "X-Apple-CloudKit-Request-KeyID: [keyID]” -H "X-Apple-CloudKit-Request-ISO8601Date: [date]" -H "X-Apple-CloudKit-Request-SignatureV1: [signature]" -d '{"users":[{"emailAddress":"[user email]"}]}' .com/database/1/[container ID]/development/public/users/lookup/email`

About CloudKit Web Services

Modifying Records (records/modify)

[](http://www.apple.com/legal/terms/site.html) \|
[](http://www.apple.com/privacy/) \|
Updated: 2016-06-13

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/RevisionHistory.html

CloudKit Web Services Reference

## Document Revision History

This table describes the changes to _CloudKit Web Services Reference_.

| Date | Notes |
| --- | --- |
| 2016-06-13 | Added sharing support and deprecated some endpoints. |
| 2016-02-04 | Added "Accessing CloudKit Using a Server-to-Server Key" section. |
| 2015-12-10 | Applied minor edits throughout. |
| 2015-11-05 | Applied minor edits throughout. |
| 2015-09-16 | First revision that describes the CloudKit web services protocol. |

[](http://www.apple.com/legal/terms/site.html) \|
[](http://www.apple.com/privacy/) \|
Updated: 2016-06-13

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Art/webservices_intro_2x.png)

View in English#)

# The page you’re looking for can’t be found.

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Art/1_create_api_token_2x.png

�PNG


\

U˶e\\�.3��Mї=GGG\[�'\*�?hP��mU\`�#e��74����\\9Ke�����Rk��1�)}����V\]Q)�e�\\m�\\�:�-:�!2)�o\[��M�B}\
�$7�R7�rE����+�m0t���ͧ���$7���1oW���!c�lOt��y^�l��~̸��1�xz��r�F\[\[;�g\]o��4U;ї7�<$����d;��\*E���:CY˛}����{Ϟ\
F@�t!ܱ���A�r�jT�Y�����5��\]��\_\

��!KMMMFZ/����I��\

�\`�nh��\|�te\]~�~mKo�\
����"7SX\|\`{��񛬫��jBVP�z��za�\

=\[YE�$�G��c�h-��B\_��H�{�' �e��������\
���N�\

������&V�11�\
�Ď���Uù�:}��m��t�ͻ�J��T�k$�ZI���Z��z'��뤻�0\
�����9�p��?�ݎ�##��VR$-�D��sUtD�W�Gm),,����zz��g\
'��$���t��r�J�8WCB$Z�{�u\|e��\*4@���}��&t@F�@G�6z�/�2�":�/×L��Z�h\]C3���y%j�s�^����K�m�iumݞ=�"� ���v��o+}n�=�"�V�I��s�9����?QAAɗos��lݺ���N󐫏sw\
4@F?NCFdמ>+�sϒ�Qݤ����g����W}^B\|�����A��(�T\_o��c����\`��(���k\]�ڢ��Df.jܪV�8T�y��~��v�\]T��f��\_a��F����+�W"WSR�;W�2�g�TS��jj7S\_9���9W)y)�H�jT�cG���Y�P��tF�����c�ɹΤ̋�M��0"W3"�;k�I�?��HU$�5k��^3��s��1Y�����8WKJJ(>>�8Y�u�>���c�SHA�%�����0F������j�Qw�

3�?OK�=���������ߦ�g��gr�g
���-���b8{����+x�XPMW\[K�k�6��\]�I��u����\]\]�&��( �" ��W\]u��Jl�$�D���H�w�m۶��$Wd�3ż�zO������ ��g��\|S�ݾո�����2�n��1+\["S������@����R�3�;�{ۗ�q����\|�?�@q�����O}Y\]\_���V2U�6l�vV}Q��'t\]i�}QQ2s}r����Wz���@���
"y���w�'��q��ς�9�ŁzK�

{۳������t��{�e�/�9YUmC\`�Y��\*}5&}s\[�)����N- �����Q�T\[��\]f���ӝ�j\*jO����o����;\
?���u�����x���a@�;��\
��k�\`v�F�y�ݸ�,HA�+���������G\`4~���Yy:�Y�y������W}^��;�eE&E��Vg��L�RdLɕ�1����Ss��1���jeS-n�EWdJ�ϵ�)}o��;��e}3�NǏ���s�����"��ҡ�Z�o�\
�A\`x�����VA@@F�����#M��m�g�\|V��{��RX=?��\
�#�iĬ�=�Z�I\[9D�-E��d2��J�\\��m���\[�͋\

\]&m)vu���q���Zܣ�Šy�JE��}�\\ƭ�������@@@@@@@@@\`���#��/\

УX�RShт��Nb;\]q{����C==�o\|�E��"iƴ)$�Z\[Z�ÑctD��������,W��^/+3�0WYUM�U�oJsf͠}�Q{�Oڱ�\|�@�!���5�PEc;�\`m��3��pű%�-�y���E9IQ���=�ա �j���Ɏ��h���,k��Z�iİ�D�6pN"q(���MӲb)���V�о�&#E�O����QF�D���K�lvDW5��6���i�T�FFK&%QFB$I~���M��~�&� 0.��\|�93�:��������KI�qI�Jn\|(��/0�����}8\] �����<�B��,��!�M��\[f'��j��i��}�\

g�仅mta��^�'9w�K\_\

��MYW��4ω�z�������0UE�O�\|�Tj�\|���Pb�:����K�p�j����#UΛ�F+ء����SI��k\\�\_Y=�����$�����U������;V��\[K��.�j8i���즥�e��֋�ʌ��y���=v�CVX{+��8��ɔ�Ek7qS���.�ISs�i�j�cn\
��:�:���\[��sU��t� �������$�E������p\*H3.ߒ/�3�Nm8��L��BmS�rD�9O�8���=ɳ�,/ژ.���%�Y �\

��9�s��$�̹\[\_�U��tBÈ4=#���S��\\�'jZi-;:���w�U�/��:�R������������륜t\\:/�^�V:h�o�4��˴~I$�+;�H9Wem1��@��ѭ��q\
��z���j9b��=�a�Q�1��5���ї�ZH�!�����Z����94!5�\]��\*��F0�G@\`� H�+�����^J�q�$��n�,O�w\

Ҽ���h�ђ�\

e@8Y�e�����8Xe��3���Iq����\

e���;ճ��g�����)����Z��q�mu\*7�ڽ��R���\\g����-綷�Ǟ�m�+;{ L�r�auM�q3\*�Q���n��}�1�C/w�q�ޥ�D�=��M�D��\*NI�^�(W�E�R��2h�왖S$��ષ��H NPs��ít�~�:���%�R�rd�&St�y�U\_�NVNE0�����F�j��V�ƌ̸�;J%"�S�Nt;.q�Cq��4�ۦ�nc��\[8�7l�H��\_����o�eU:��8ɫ��z��:?/��\\�E;��8?��9�Vw$��E��߼��}(Ѧ\*W��)�Y�~��=�Ȍ�g�s�{3�\
��yT����+���zߜ��u-����8�u��t#��8\]��\|�ӿ3�8U�����J�T�ӯD=�%�e��kgE���q{\
G���Er��s% ��������\

\_�5���S&�s'N�o�UN?\]�EY��a$K���85�'�������V�\
�2ؙ�t����F��eL��UmV��)3�Hߩ��\\C��hm�Y����Tǉ�n�c\[�ȥ�q��4����D�N�:�#Z۩������K�=��4&NK��~ƴ)����T��4N)PYٟ�r�$�Q�=w�D����\*��r�+)\_\`�����M}���ݸ�vJm}=M��d�\*G��,9Q����-\]b8X%�ANN��c���v\
��}����\\Dk\_z�HW��P�M��(��v�1��\*{Ki��dz��"KǢ՜�u�ɀ�\
��Yz�mU$�k�� 31�~��a����b�܅��s�\\�W�؎��{���L�����?\_�8b������Q1�&EӔ�v�&Ӫ�81�\[GmyۭS^��d������=T�l���\|�AN=���Oaƙ�D��ec����ɭZ͎�v�fǅ�X}\\��1"���L�ϧfG@@@��#0+=�p��\
��ܢVG"߄��Y�X�+����E��W�\|��tZ��r���S{���:��5�j\]�9Q�������fgD��v�����&�şcU�2��Cr�?q��y����~������3(1A1��f�}lkz�g\[�9�W(�j�Tܺ�#O���D��\|ט�ٶK<"\

��.��KI�hn�DrcL��Ŭ���P?����^��5����~�a\

iii��Hn�#7�\

o}\`���H.�s��VV{tHʴ�\

�(��Ȏ�gf.�sU�H�I�I��̖e��E���؈d��ode.�oZJ$'i��nj������enF\|��KuXOje�m\_җ��Ҷ�L��ոj뵴�}YO�H��U\[�%�a��e���k�南�r��ՐC�zN=���jV����lι���F\|S+�kW���7�je\]q�JD��%44�r�3\

  �-q�JԆ�Dqniɓb��WE��S��\[�5�����TN#��չ���\
t��E���\\XC��#\\)�ĩ\*� �:�i1��V�✫����h��\[t����hp���)�VrG��\_�+W�"ɝ:E�O������s/����ӡ�XA@@\`��ȃm���O�r攟86�H0�^�8 �QB@��4�qV�y������C���?�KI���"��h�r���V��T9�T�IwD�F��uH�c�z���麫WɎ��Ϯ\]G��x\*�����pq�   0� �s4y������?rS�@ɻ{��8�(�������N�ݛ���������%�4�\]�/렀������������\`��Rn�����%�{�-���Kh�����H �~?�\
\
�T�7�ڳ��y�q��78L�q@\`L9X��%�K�ձ�9c\*E��a�J          @+^          �'8X��i          0��Axz@@@@@@@@@@� �Z\_�hv��         ��������@@@@@@@@@F38XG󳃽����������j��zw�����ѾE��%����qy�8he�e�a6A@@@@F���w�&$��, ����"JMO�e\
tA@l4�TQVv��(�     ��R��g���\`�O\

U�(��)���˩�������7^M��M���H�m4u�Bv�^D\

���)>>��JdD8͙;�R�����:A'N�Szz2��gSKs+�M̦F��688��ΝJ�����J�C ���Σ��8��i$Y#'7����-{\

�̤��L�G�т�SrvՖ��F�5����8t������TS�@UU��D�062o�4� ����\
���%�٩�fD���%Q����G����\
��:x��\*\*�S��G��O;�4��N����!v�Θ�˽���A&d�F��p�P�AT�w�sV�t�Cvv:}�y'��wҲsPVf\

u�yOԙ}�ɔ&8~\`���p�� O\|�E靐佪��(-�7��2�����QS$��y�W?�ʲ"S� Df���L\_�9��\
��5UR^\ ��n���\|{�O�'�s�t"� � p��\`�Y��@�;����\_�Tv�\|\[�f��yv�?~Mm\[%�}�-��\_�����\[��/HYq�\_���7% 0H���?��r�,x���\_?e��~~����<%S�~�Ws/�sz�kg��;?y\]����\
�MK\
�Ț�!��'����2��߬�PX�����5� � ��t�7��"� ��#/O\|�M�\

������O'�Λj�l\_��#=�ii�6 � �-�t�AG��#� �t��3�{Iv�yǔ\
��:f��j �a3B5+�y$����=m�?�Dՙ��;%u�4d=�{�\\���s����q3\]��5���8�-���2�۳��޿�ʵ��W�n;�:?�<�����94X5�ֽi+\

@@�c�΀V���Lw��ٝYYY���+��/��A�r�D;RN:��97Y �O�ܛ�K��̿�{nyw�W��٢J׊=C�$&$H�j�$�򪫿���5� � � � �ܱV�������<��v#Co����6F�������d���G�x�nbR�L�8Ib{�JIq��9sN�N��چ@P3����d��D3�o�ʞ={�Rf�k?�<��������:L�S�� �?w^���q���X�z�F8 ZΠ�-!!AF�)�֬m���K�Ȯ�;e��y��$ӦO���$\

Znذ^�y��&��� �����r����&su�ʕr���r���ԍSL��&�U�f�M�.}��\

Yg\\ղ��~����p��z��Wu^����\*l&kT������\]��\]T\`p�ȿm�&ߛӽ�^!�� � Е��\|vM1�a�b�#�?x�&\_��.kr��Xp8���j��\*N�L𲩩�ܲ�kwI�I�k�����A�������\|�L\
\
�\

S�u� �j��;MɁ��e�xH�2Y�L�U����P�3��\]�Q�T������R�6�W�Li\

���kL����w\\��yh��ON+���?e��cf0��.N��&�h��"C��UW�Ue��R�M�\
�,s�=d�j�m�2\[W@�-�Z'oΖ/��/�j�z?�\

\`��ׅ�B@@@@��@��m�"q� � � � � ��X��u�@@@@@�6 �z�H�" � � � ���V�\|\]8+@@@@�\
��/�� � � � ��)@��?\_�\
@@@@n�����)"� � � � ��\
��iqV � �� ��I\`�,z�ܶ����k� � �:�~���nE�B@@� �ڡ�\
;p:O�����Ƒ@@@@?���8� � � � ���V�~}8;@@@@�L�.@IDAT�c�~��pj � � � � ��X�����@@@@@�����é!� � � � ��\`��ׇ�C@@@@? ���/�� � � � ��-@�տ\_�@@@@�X Џϭ�O��/~�u����k� @@@@@�5d��F�u@@@@@X}�Ѕ � � � ��F�˗H:X}������В�ҏʇ����\]d���Ў��ry��r���m�A@@@@T��X5���eȅ����E�R\]\]#�Y�w��A��'����?mK � � � � ������+��/��Y�d��T��;N�m�����;��Jt � �\]\\���^�^�\*!!!ҭ\[�.~�\\ � �m����8��G/7��ÖEGG�/(�RRRb2h�:�8�@�,555r��1).n��'00P�\*���e�v���j�\|������)h{����R�\
�(���rٽ{����Cf̘�z�����۷K���e�ܹm:��\
d�رr��59z��̙3G\*++E�����dĈr��I�9sf��{��y)((��'�zVD��wt���s6�G���4y�L0�JKK���������+�e�&),,lz�N\\2q�D����uk�٣���O\
\
��jMu��bP� y��G������l��v��I?t�cYK3��������A�\

�0�uz�����Ӓ���z/MOO���f�j6��~��1))��=���C�f�������:M�C�c�N �@�\
t������fN��)'5z�Xٱc�+����@vl�a�W�\
�)���AΞ9-����hU����~(\]F���� � �J\
h�w'��l��E\_3P/\]�d�5h�\_�5�YX\`��W���A\]\_�\`���o絖�3f�͒mj{���Y�o\\\���9-a���h �@G ��Y^^�}?����?�����u8����q�D�Ҡ�ŋmPU���@w�u��w{4H�?�{ZBB�\
�jy��ch��W͜�LW��J���e\

��{�~�Ҧ��~e�L橾�i9��P�\_ݗ�su��F�-E���զ�z,\
�jPV��ѫW/��D\
��@n�����������G\
�,�y���z.�N��y��ɦM�m�P��8������y�sO��"��B�Ǩ�Q����ҷ��A�4@��SO�ES�l�ҥ�J����"������W���K0���C��yN0�^���6��a�e���Q��s�L��5Xu~}�:S;�aٷw��c������Tƌ����h�}r�d���i�ys��6�k��b�s�%�y�&9u�d�C���aL޵c�,�x��^oc\|𡇬��6"mUG遌V��J ����t0�u����m۶٬)�\*�pզV�\`��}׀�^�9B�\`5�Ko�wJ\
�\
?�����j�i�O �Y�,V\

��j����$&%JllO������6DF6\|�n�&�� �C��G�?tiV��!���뭫z���\]զ\\���i����T��\_�D���N��7y�d�4w�h}@�9���Y��k{\
jhvv�-)�A�hՒ��\|t�\|��7� ������}���@��7j&��4�U�j檾����{�Iu\]��I������M=�{�tu��M���d��\`����4��ɨ�c뺚�JC�\\�;.��b� 1Y�'�i$�o��X��Q����/{vﲏ�ec���8\`�7�a)4�˭4Ĳ�2I2������6�3�6�\]S����^�uͼۖ�7��˚�?\|�m�V�n��L�t�:x��vh�P�l�Z@@w{۠�y��d?\|�N)���M���͏�qq�D\[2�\`u� Hk쾽�̇�\\{�,���t�F@7\

�j�V���@�\_ߧ�x��0\
���N�-���;.����}��\

@\|h Um�/�ZR����aÆyl�\_�O�nK\

Nji\_Mo���:Xu��{�j��:hS�)CཎK������zo�����A���G���3���ɓ'Z������f����׾Z2�l؆A��䪏lX\_�������L�̏/�@���3Nɩw�������l�l� � ��-л���Ll�Y���2��OP�i�g�����i��̙w���y}hs���~����j�����J���\|)jMP��x�\_M�U\\\�kQ��t?޷�k�Vk��^��M�j���\]\[S�i�L�#/�q����G? � � � �� \`mN�e�BBBe��ҧO\_پm���h%:@@@@�C�\|����\\\
�/��%4���4-o�v\]y�ݽs���Z��k�ve'�\

�.&@���k0� � \`���dȐ!��\|t�a��@xx8�\]����@��/���o�@@��^@��/���m\\ ��ۣ�6 ���+@��^��ʊN8\
�@@@@@�� �� �aa�p�@� ��v��8 � � � ������85@@@@@��������!� � � � ��?\`��W�sC@@@@� ���/'� � � � ��,@�՟\_�\
@@@@�Z��\_�<� � � � ���V~u87@@@@�k�~��pr � � � � ��X�����@@@@@��������!� � � � ��?���ݪs��+�Γ!)��N�� ��l��¢\[uJ@@@@�P��׋�+��\|�/HHH�kɨ�28y���ׯJ~A��� @@@@����{Fjppp���+�S��5�#�ꬬ�Ewϕ7�~���@@@@�p�.\`Ռԯ~��q�v���RYU��K���kr����&��@@@@�<�.\`լS\

@@n�@�\[\

�j�5,�q��zMM9�.�G�4e�w�r���&�z̵ɥK�l��a&���Ly���ol�{Ƽ&�)ɶL@� hk�޽�8���H�ɤ�!� � � ��~�����b�\
nj\
ԅ��t\[�tY3g���:j���\_��ǥ�d���mo�׬�������4c5\*:RJJn�����Yo�o�UV�7ZE��u\]CBB'�W��%%%��v^��M�Y�UW�8��g-�������B�z� �ֱ8h�)P������kwou\_�x�G\

<�N�A�իV�ෳ\_�@@@@nϴ���o��,\*.��955EDD��\[�Y����׳W�kLH��їп����ے��Ds�y��y��G�����4Щ���X����PX�ڟ�uۺar��?:n��F��u$���\[b� S#6�gF���zνzŉ���l��9ޛ��y���pcbc�@Zhuo���3�0(�qI�a;�H�28E��^�n5����cr��A3�X��� @@@@��G�k'�V::�����h�H\\\��{��m�Z GM��Ӛ��+ ��������t���s����\\uCu��S�2��3��\
�P����S�{b�����j��Zi��}k�i��0q����jճ��ׯ�k\]�ϴ��eϞ}��\

��}z���;���\\;j�ĖM�챴������e�9}ʵu�4j�ܹ�Xo����ߙغe�\

\
�}zȪ+�����\

\[�\
+ݞcǍ��C�JpH�lܰ����@@@@��t���j��f��K^%??��ޱue��4�<��g�JVV���Nt�+�q,Ct0\* � � � ��wD����������7w�����J6��\_4@@@@\| � S4@@@@@�v\`m� � � � � �\*@���@@@@@�v\
\`m'�!� � � � �X�o@@@@h��v± � � � � @���@@@@@�v\
\`m'�!� � � � �X�o@@@@h��v± � � � � @���@@@@@�v\
�s�N۬���ӎŁ@@@@@���}�5,,�-�ú � e%��p� � � ���%��5�@@@@@�O����i!� � � � ���\`��׈3D@@@@? ��/�� � � � ��/���\\�?!g� �t=��\[��իW\]ؐ!CdРA��O�:%UUU2f̘F��@@@�+\`�W�{��)U�R\_W�G\`� � �@�\
�?^�\_�.W�\\�K�.�ĉ����;���@@��L��X#��d��ϸ��jk�('W���$e���\|Gv�V.�p��П}M�m�%������������ʙ��qX�}�}m�e��� ����rr�~� ��ϒ�1#E�u�DN�O�C�zl�l����N�r����풟��Z7�G�<�祲�LV�򆤌-�u-w&�Lv��?����\_�>��=��k6:�yF@�,n�)..������T:$f>;���Jtt���srrlP6--M���ǏKQQ�\]����:w�ԙ�+++E�ٻwo�e��ӧOKJJ�DFFz�@@�Q��Xܭ�},%��(L0r�=�e��˜��>g��+g1��n&H:J�Λ)��O7����qfK\|�@Y��;�rM�s��z��()3��C��i�x���y��;�~�׺����u�\[�Xl�f�>o��,�QӧH�L����f�����\|��X+ 0�\|a���ƣ�z��3��>>����\
S{5 (P\*M6H\`�@I:X�\
�&�i��H� 0���lZ-=PUV��0t � ��pj���}�����<T�lU�ժY���5U������\\��l�jFF�ݶ��WWWKvv����֦۬�s�����/����4 � ��&�����~�h \*�����!.X�J��z��ӊͭ���7d��ss�}��<~�Y���ҼB�n�7z\
����нRg�����Mn�,�K�7�Kv6)m�\
��x�;\_w���i�og;�ѪٮU�:g}=��Q#���=�j<#� ��I@o�1�\|�0�S�J3Vu\`���\`��6Lv��-YYYv�#G���˗my�J3\[�j\`��4h�eh � ���@��6���eK䜽h�\*�!��\[�\
�n�61�GG�\]��O���0�1#�:-�g� ��pA�:���G=�~L�̙&e���+���g��$�63��O3M�~kdl�l��8�;B����&�n�?u�L{��\_镕�h�\]ˋKdů^uf�ݳm@���� @h��f���i}���޽{�A�4���گ��;Moٟ;w�3k�ҁ�4��� �{�:u�kv����i&@@�w�;&�z��4��%���g�kR\[Sk뛺I�O�(�0�¤��RNH�s��HxlC\]Ի����\\�����k9�ٲ����\

�����@@@@�%\\L � � � � �m ��6/�F@@@@\\X\]L � � � � �m ��6/�F@@@@\\X\]L � � � � �m ��6/�F@@@@\\X\]L � � � � �m ��6/�F@@@@\\X\]L � � � � �m ��6/�F@@@@\\���;d�\_\|7&M\

����weێ=���a&{սi�U�{��w�v�=\

�:���\\UY)G����9r8Vw�@���l��G~pJ� � �-
DFF�����B�����j��7q��d�:���ɪ��F}���v���sr���wd��q�%m�( ���:9f���w��"
3�3gϖ~&�V\[�ɮݺe��'\[a�\
!ݻw�% �F�ITT�-Q\`�����2lx��#F����1%����܎9�ZG3^�Ϙ&&J@@�\\̼ �2$;�Ff��:A=���P����QB�G���{\_RS�IrJ��8q\\Ο;/CS�ʸq�$:&V�^���HUe���:ђ���� � p\
��z�}�\
/�SF@@�Kt����\_\\\��E���h��t��֊./-+w��s^~�������ș#G���0\[O��d��9�{���6l�ؿO��C���=%���~�Z\[?uT�(y��e�\[KM-�\*P�0����Qr�¹v�Q:t� j�s\]�� �E�oՊ�RPP 111�x�\[F@�- 0@�\|�I�x�,\[�T��j%99E�3���^����F�h߀�~6o�$�N����o�R�\
���F�Z�G�J���&�&O��WHn�k3c�L\
\
s�cK~��@@@@@�3\
t�������RQ�8\[5 ��K\
\
�3��w�2ː����O� �Ξ\
�j+//�۶I�O��cƎ�,�\
��^��3��&��n���6�X��Ѳm�Vs{�^i�6 �&�;��1z�h��������k�5�t��)���OlpU;u �O�/� 'H�)�0v�x)+-�͛6�@���LO?n��m����2��\_�� \`3gϴY���������b=m�q���L�6\]V�Xe���\\mt��p����װ�"� � � � ���lkM�U m��z9+��\*L�cx#�J�=s�B��Ps�~u��-�V���/ɜ�s��dҞ={�f}jRڒ��d׮��x��i�k�Tٷw�\]���+99-�gӠ�A�<�ףG��N��˳�������6�Z\\T䱮�UZRl��3٪�r��A��:�e�fW\_S���\]�&��@=\|8ݵ\]\\�^R\[w�d�6���O�����-��v� � � � ��Q��X�L�0�Q�U�Z�v�<��}��֬�l�A���+����m��v��#3�{c�Uz��u�}���5�E�L�l\

��\\��������:u�n�^b�u�Q���tښ�s�DҮp\

_�}���t��v��Æ\|7؅0��)b��<��)")�qJr�_\
_6Զ",��V�L�~��N\\%��^g�����\_1D�����:q�4<^�0�ڶkkY7��e" " " " " " " " "���xdr8�\`D�\]�"$��Ǯð�ݘ����N�ܳ�އ �Db�bd�#6'�P�Bֳ�I.�����4Y�j�@�dK�.I����)S�þ�q�l�\_�Q9l��m����.�Z��NPE\\B��uk��_\
_��ɺ�l#�ن6c�.S6�L\]�_\
_�.S�N���yyFײa���$�\\�@kӦ�5h�0�z\_�y��X��RR6�̟61kt�\]�Zm�y�\[��e��_\

_%/^,����V��XժU\\��X5$��j���gjrpxW��z�(����\_$ZD�D@D@D@D@D@D@D@D@D \[d��b�t����R�ʆ:f��n�x�S5ښ�haG}Tt�{�\_�����oi���!R�J���߼y�U�P)��ojԨ�o3u�Y��v�a�����ح�ly0�J�\*:����_\
_6����q�WnU�R��b_\
_g"��9�c�˔'�^D@D@D@D@D@D@D@D@����lC�~�lc�\\����p;���헟�$5~�x�#�Z�ݱD�ީ�w����U3�Mk�ܝ���:wl�4�ʕߵ�~���V#�S�\|�H�7r!" Q7�6�Xɒ�b�F�r�l�?�G��P�!i��Λ�)٦L�l\]O�F=����nݺƘ���������_\
_ܵ�\*d:v��+WZ�0_\
_�֯\|" " " " " " " " "�(�H�T�;�Kュ��ښ�kAp����3\[�rE��UA���Z��z��_\
_��\`�����ȟ��1�����'Y�_\
_l۶A��26⧑A�\]�+���e�S�Ǝ��/���(ݾ}��X������ծ\]7�~�f��ivL��N����ï�=�n%%��^'��ǻpϿ\`#G���Ga\\t��Z�tIw�U�O?������ذ!Cݸ�^rq�n�U�^�V�Zm�H5�+" " " " " " " " �D�S�_\

_�QDM�N2D°!�!�"~!�qJlV���!��n�ډac�S�E5j���Ũ�WOXx��q�{�S�?��K^b���-�����~�������_\

_oV�S��D ��Q3��-�l�����a�x�x�"�"�"p!zz��~Svo�b�_\
_c�8ުԏ��X�<���a�;�#B#a��2���Nċ���sX��\[���=~��(_\

_�_\
_oSB�M�B�D��\*������D�%�C�FP�\[�kx�"�"�r��fD��a�l nky�\]v�۠�_\
_��j˂0�E�vQa��_\
_cnw{�Y�@�<.(���ʚ�۷���_\
_��"�bl���g����w\[����/�ؽG�뮻\\y8�O\_���x?z�h'ԺB�?z���D�^�z�Rw߲.Y/��B�O�k�\[nq��k�E�q���\*� ��_\

_���s��x���"1q5z,��tPtr�Q�^�z����Xz�YG���3s�Gr%j��D4�w�P��q\`�,6���!�Dn�l��s�����h��@#�������������Ws�T�#" " qH\`�&��/��r�n�g\]�v�#�:2�k��������������������B_\

_�w�ٳ�='�?��_\
_f;w͚Z�nݬB���i�&(��d�V�r�m��ݭh�b��HF݈������������������A��X�Bl�5k��9���ʌmܸ�~��gk\|pc7�u�� �Q�8�T?�ӦN�:�ʖ-k�֭�v����҈��&N�J�+GVD���f�~�\]��U�v�Z�v�;�sl򤉶}�v߄�" " " " " " " " " Q8�5j���qႿ�����_\
_mΜ��e�f\[�p���� �'��w��$�^�Z�uZĊ+�\[g5kնQ���&3g̴F_\
_��jժ��W}�_\
_6��uk�:�G���t�M@�n�z����_\
_\*�_\
_ޥ��t�g���mۺŚ�laG#����γ����͛S�@�֦M\[kа�/Q�y��X��RR6G�/U��mڔy�7ɛ6�\[+\]��U�\\�.���H����\]b�O�UD@D@D@D@D ��P�b�_\
_k۶m� v��޼ys�9��֩S�Ȼ�q��}3f�լY�jԨ�%� �J�¥K��O\|����\_ٔ�Ϣ��C��s/7n�g��6g5�?���\*V�h�\*UJthF�S.?\[f�����\_�cp� �-�}!Pp\__\

_W\]uU$=�n8��\[nq��Ǭ���9����?��O�_\

_ސ��Ye��裏fUu��������fxDg�x��ƪ����Ƀ5�V��kԨim۵O���dɒvB�n��Vsm���7lq���+R�H�w���v!R���ï6\[i�G�qXU��_\

_Y��I6����?�����oР�m۶�ʖ+c#~ik�\_����F�\]�f�}��vx��֣g۾#�f͜e�gϱ:u���lؐ��L�K.�U+W\[��U��\\W���CV&" " " " "���=�1�pa��׏�0Ny���C�A�$�)e_\
_����1c\\�t�����8�\`���u�W���8\`�pb�S�:���@����� \_��+O����s�(�\]{���@w�:�_\

_�E��D�)�J�\*n^�7��9C�����7�����\]m��npp���#rq����z�7C�Ch��=ބxΚ5ˉ\_�BW,щ�훸�~�=��\_{�5c<��\[����\]����B��T�R��x1Ο?߉�0�H�T��m����wު��k׮�#�8��<�x������8iժU�_\
_v.wޤi�2R�2l�52��s�V�ܫ�\\W���#�X��X�ɘ���!��e_\
_���;�bŊ�߷�X�Q��}�\`�͊��u����6��U�^݅߈^��\|�������hޘ�ݽ��?������'�@�B�!\[u!u�M��\[ԝ���������@F ~"����_\

_��'����?�����b�w�����w��-��;�wl���q��5�#��3"1a���ߔ�"p����˥��J�Ҟ�\["p�ذn��;x�\\D@D@D@����\*V�L'Vp�_\
_��\]�"I˖-�C�WD7��M�6�7)�\*ֹsg�����sF�?�!����t����ǣ�o<�Z�{�U�^�gu}GL�6�5k�8q�w�w�q���L�b��\_~q�Q�u&����������F�c�Ѱ��$k׮��Z�n�Ң��-�.y/\_DC�@��K�(a�~��!�b�����H�=�%K�tޙ/����b�+z�_\
_SRR��;�tB�?ޢ����Y����9�jz�@IDAT�;蠃���#+�x�"ce˖u���P����a��a4lxr�}(W�����b�G�y���zc^���F���.��'�RG�ڵ_\

_�N�XF��M�4I�1��=^�l-G��Y�fD�OS �kM6m�ԭU��W�_\

_qh ˁ�<^��_\
_����~r�oɓ^}�v�fIY~,����雠U " " " " " ���� xp��F�LĘ��:���H�{���㠢�2��84_\
_û����x�A0F��kCȤn�O��V�ZΣχ /1N9�)�(��~��2Rgz�L�Ox���kF�\]�hoA�_\

_6��\_l��\|ƏoO<�z�Ƹ)������G_\

_!��������=�\\����OmٲeV�F_\

_���?��\]y�����(\]D gH\`��jED@D@D@D@D@��K!O9����G��a_\

_����t�D���\|�U�'���H�Xy2 U�#�iΏЇ�)\\���<�9�\[�� �&(���x<=��$�lq�\[��\\\|�w�ٳ�;�!�9� ��4��ޫ���\_�7�����kzec�C���\|�ɏ_\

_7��h�P_\
_m۶u޵���-�$�e�W�����L��u���{�Lo}�y�{���^��7޵����;�~�.X��ķ���)���}��< j��r��W������\_�}���"��7x��G�b����8$���ęe�,6�Tm�C�޻;�}�g��9p�K�.�(\]D  ���s�Jy��W�c=������Wiϧs���+�D\*�ڮS����LD X�d�r�}��G����\]�ϴ��nͻP�E �@\`��۹?���$ۂ��q#R��я9��Q�A�җ^z�řD�a�u"����ەc�!\\���G�_\

_�����-" " " " " " " " "�A��ڭKg�\_�����;�k�+Q��u���n��\*{���-9E"kב�������������������I��X\[6ob�����\]��Mz����wR������#��\`���s�N��$f����^��D���o��c헟N�O" " " " " " " " " ��@�X۴jn�4nh6n�1c'ز�+�l$%%��ǌYvr�"3ֺe3k��\`۶u��?���\[y���g�~&M��^d#~is��N����E �r�T���hv�)R�\*�/km\[�����u�\\�2�gS�X1�����-�5�_\
_Z�ŭM��ϯ��������������������M �z�n۾-����#V�P!۾#5��o�m�fE_\

_�ڎ6xР,����@�X�@���&��������_\
_b���({뽏#i�sdG㝷i�gX��ں�����Y~m٪�-^��ƍ�=R�����B�J֬ys�^�N-��˯#^�ɛ�m���V�V��J�ŋ���߰a����OkԸ����\[$Y��d�}��v���0p������������<v����k׮_\
_�\*v;z�\|OԢ��d�@��ŭT��g�,����6�����%_\
_"\`�J(&����و��������-&_\
_"���HwHw���~�Þ�93g���s��uf�z�k�w��D�\_��\\Ԃ@!�gV�P-SzW�Պ�ۢ�K�wh�~��ݷ��_\

_�T����8�f̜mY��Y�T kߡc�8��֮sc(\_��Ҫ�U�\\ɶl��V�Zm\[�Hp�W�b}��߃���Q6Z�_\

_@� d���\\l՚5k�\[WeV�Xa���ݙ5���'����ړ��u�\]gM�6��o�ݦL���~���Ov��G۷�~��\\y�v�UW���jC�~��g��\]��_\
_7��D0�K��~�iWvӦMָqc��m�2���_\

_P�re'�z�4Vy ���m���)/z���ߣG<^����\\�\\���_\
_���z�!��s� �� ����W��A� @{L@����x�5�x\[�c���K䕇�O8�{���6�I�&��\_n�q��5^޳�íb�Ŭ����\*qUb��e#�ȭ��_\
_��$�4(V�KSUo_\

_m�WLT�P<�T��(.垆Ho"mڴ����tJ��?�R���ꫯ�����UW<�����g�}��#�Ȟ={���\*��/���;�I^�ʿ�曝�'Q���~2mc��W�n\]S�No'N�-�������V�l�ر6w�\\�U\_B��ެ�\`U\_��:t�P7�m����+�iӦ -��_\

_�I��5~}♶�G\[���2��,�Q��L�� ������bl�V�p�=���.�i�ԇ �W �x�uݚ�1j��0/@� @ ����=Ws�%���1��<�1@�@N#��֚����1$3�)�$���; @��:v����!@y��b�b� @� @� � ���F@� @� @"���{@� @ �dx��A� �� ����c�� @�@.$���K�,i˗/�-\[���0d@f��ϷB�_\
_�IO �r��+@� @ O(W���\[��V�X�ȚVxڴi9\`��@�"E�t�ҹkЌ{��^�J�� @��#�&J�\*e���Oz����_\
_��{1�Cȳ�$�.-� @�r2� �G����+��!{GA�� �\[ ��֕c�� @�@�!���g���@�@���$\\t�@� @� d_\
_֬�H+� @� @�@H��K���W\]bmma_\
_,�}�v6b�=��۶z��$\|_\
_�2 @� @� �I)��w�_\

_��"E�Xɒ%M��6~�x���7�\|�S�b�\\�����.��r����B)h\\���줓Nr�T�{�v�r������V�Z�8\_q�nH���駟��;�yA���^r��?��A��^{��CTsS���Ʈ��8g�w~��Gm��rK�Yw�9������?�\|;ꨣ"��5�knS:� ��z߼)��/�?����\_^�_\

_:\`��_\

_���3#�X��5�T_\

_\*b:�^��HtThy��\[��k(�#�9(܂�H��\*Shy�\*Ƭ���i��@e՟����#�<�y��%�Xm\*}ٲe��+-3�転�Y�a�I��7��+y�Ʋ��K��XijK\[�=^�����I���\|��..�/�9�Q�i��/��5޻WՎ�л���4y��=�g�⼆M\_(x!W��æg1�֜}��@��f7\\s�^� ���~��?�,��ٗ�r��Ohwx��န.��cϼ��O�ᵷ?t���y��-Sz�1(�@���\\�ֲev�&\\�\|���H�¶f�� \|�T;���}�^x�_\
_:�US�7zb�^{�\]xE� }��zÕvh�� ���� @y��_\

_�R!�cTH��S��xO�-��X��X�W�׮���2ͩW�^.,�Be(Ԁ�닃x��9�k�td�@�;s^P^�q�Z����qUZ8\]�r���g��k��O�\\^��O���\`_\
_\|��w����X�^���Ǧ�/����(�ӟ_\
_�U$�i����w�W�\`�����Y�Z�\*�C��Y���\`���Z��=#�\]�����sV���k�X���O8oU��ꃏ��lg:���k/�w���͙;�7�k������꒥+�'^�gO�+.�f�\_�Sˆ��þ�i�0�V��+ @�������5gyCf��K\\U;b w����֎:hKi��^t��ָ\|����\`��$Zַ}��}~Zk��Ļƛ�b����%^���Xk�9�����b��i��+\*�/�A�/,��@t߱xE�\]'�s��P�rJߓw+��X��%�{���ҳ��9�vɇ@^ ��&y�z����cUe��x�T����U����ϧ���W��3V}s����A���)\]\*�h-m.�-���Ѧ�75��l-�h�V���v���W�jT��b��X;y�ŭJ�_\
_N��\|�m��G��y���u߱�'@ ���5�13�Yr�k΢�h ��@@��Yabـ��-Oi9�@����\`�r����V�Yk��3m��x��e\[�l���U$h7،���ˏW�t@� @�@�P,\[}�Y�v��e�d���� @Hr�pܴiS\*_\

_#�%��rֳ�����}����g���u����_\

_� @� @�+� @� @� �L@\`�$8�A� @� @H_\
_���{o��ҙ͋� � @� @�@�H_\

_�x�l�2cyۼy���c�M�0�j��_\

_V%z%\|֫\_�j�Lq��7\_�\[�ա��S���w�_\
_:�V�j��խC�N�h�"W/�9�\*\]\*h�����w?�y\*��)����-\\l��l��~ZNaT $/�C�_\

_�u�WUp̘Q�gk%�5s��\\�ҵ=�\|�=k�թ\[ǵ��J�\*e��ŉ��(�v�ԩ�x�J̕g쎀Ǻu�ܽk�� @� @�&I-���������u��������@��ٲ��)Sv��k��V��ڑ�3fE��ʹ�Ӝ��Wm�߸q�-^��'E�'L�Jq�Ə���av������������V��7 �_\
_1�d���+V��ĕMtN�/p޸�֬YgŊ'q@� @� �A χH�����uU(�촒�Jۚ5��J�\*a�;tt���cZ�v\]$i���{�~�z+P��)R4��~�!� �� 輝�f�9\`E+T�l�od���Ͳ�K�f����ǩi�fV�l� ��\`W�VJ\`ip0U�j���Z����Ҡ�_\
_�\[ɒ%we'uѢőf��ȣ��2e���5��8���L�$:�L6O5@�@�ȋ�0M�Ed��B@�\*�?ق�N!@y��.�<;���1O�5~ɬϑ�i�J�u����.6tȰȡM��Út�U��K�/S�LP��;�ʏF�X��8�x����l��ѾH�q�F�0~����+\\x�Hz��_\

_6Y���dM�e @� @��.���\`�V�W��AV���#�!Q�V����W�g�~n+�/���������'��u,�\|&�u�oCR�Q�-\[�\|�_\

_9au۶m�_\
_�p��?�ȉ����U�V��^��Ql֡C���aìl��A���.�k�@�F�J���š��9bd�Ԯۗ\_\|i�ÿw������7�߇�\*��6�\]��I'�� .l�wWi� @� @� ��$���V�����%Z�vm�\]�^�:�2��_\

_� @� @�@X�D@� @� @� �ƢB @� @� � �&�"� @� @�b@\`�E�4@� @� @ @\`ME @� @� �"���_\
_i� @� @� ���$�@� @� @�E�5� @� @� $@�5H� @� @� �@�X�9)m��_\
_9i8�� @� @�@�@�X�+,7�@� �n�ʜ1F@� @���!�y�� @� @ȽXs��1r@� @� @ � �f��= @� @� �{ ��޵c�� @� @�@6@\`���{@� @� @ �@\`ͽk��!@� @� �l&����@�� @� @�@�%���{׎�C� @� @�L�5���!@� ��G��\`��OV����b�Xv��=3�W@�@�(�uM� @� ��K@��E�؀�;l�B�+vεny�������oV͗)�6m�O<�N=�T�ٳg���l%�����/���E�f��L���Ol���v��Wg�_\

_ ��b-OϹs�ZӦMs���\]�p�\_�իg_\

_�g�BT�R�4΂:�Vu$�}���TG�u�_\

_��Xo��ʒ@� �\`� �� @�r=yXJ�\*\]���ēH�0~�t� \*֩�y�\]�����4�K޼ �u�m��t����\*/g����U��x ��{��N��$B�r��K��1@� ��^�(&1�o��W��S�'�0�I\|�06={QV��\*T\[���Lq0%rI(��)�i��L^��$j�-��e?$����4\]%�i۸�)����+����P���I����d��qjNT՞8HDԼ��W?+��7���,���b����<�o��� ���\_,_\
_Xֈt�=Hk�I��ѫm��V�,\_z�%�\*��Lk�-�_\

_�p��׻���o<��S�B(�o�=ܗ��ٳ�=�����Ϻ/\|���V���r�߼�\]�N׽�����g��k��O�\\^��O��ߨ��� @�@v�x�\`���'�X�v$LfD\\U���aUZ"��t���w�Y)aS�{�5�6�e2;�p{r޿������ku�S��\_�U1W@��\]�e��:r�H�N������HN�/7�1s�jχ�H�y� ��H��q�3 @�r8�JU��N��d�_\

_@� �!��O^2 �VUD��a�\|V�T� ��#�oe�<�� @� @�@�@\`�r�4@� @� $�dYi� @� @� d9�,GJ�� @� @�@�@\`M��f�� @� @�@�@\`�r�4@� @� $�dYi� @� @� d9�,GJ�� @� @�@�@\`M��f�� @� @�@�@\`�r�4@� @� $�dYi� @� @� d9�,GJ�� @� @�@�@\`M��f�� @� @�@�@\`�r�4@� @� $�dYi� @� @� d9�,GJ�� @� @�@�@\`M��f�� @� @�@�@\`�r�4@� @� $�dYi� @� @� d9�,GJ�� @� @�@�@\`M��f�� @�@�$��?�ئM�l�̙�b�_\

_�O�DVyK8�)t���g�2�t�+Vy?�{/�p=�+\]���j�����:a̘1֩S'�z�Yg��ٳ�E#��֍g��/�W����+{��\]8�!^\]�!@ �d�\__\

_���͚5s��۶m�ۛn��z���\]���V�Zy�^v�eN@���i�&�ɪ���U"1@��ޝ��U�?@!,���H��}�7A��_\

_;u��'L�0�cs\`f��1XI���~_\
_v�@�3.���i�_\
_/m=�'@���+ \`�c�g @�tQ !\`���T�ڣ�ə��1�9�,@7���陉ٍ��M}�  @���_\
_X��6 @�F�@�gG.�\*�W?���-�0�  @��a��_\

_̙3��w���8���4֥�r, @��$�\`��.��{Ռ;����������\]~�mO;� 0��#h0u� @���#0cƌ���x����+��7��w��ٳ˹�����\|q�e������\\b�m���o��r�)�����j�g�z�%�_\

_��;.�m��ƭ��Ś� ɳ�B�򻬛?ӽ�gm\\������:�z<\\=��uO�m���:�y4�;�7����u���U����ٞ�bk�� @���@g��^t�}��I�&-��'N�g�vP��h\[�c��� ����i��Ι��l��+�\\��FI@���t�:� @���_\
_X��6 @��F\`�5׬o oM�4��@�T\]"@� @�@^��W� @��e���� @� @� @��2X��) @� @������ @� @��( \`\]F8� @� @���;����\\�����\[�.�aЀ����& @� 0�&M�TfΜY�ϟ?�:?}��Q�g&0ƍW�L!0������ @��������o<,�vQ @�{�螥� @� @�e�Q6�K� @� @�@��ݳT @� @��L@�:�\\w  @� @�螀��{�j"@� @� @\`� XGـ�. @� @���v�RM @� @��2�(p�%@� @� @�{��Y�� @� @��Q& \`e�� @� @�tO@��=K5 @� @� 0���l�u� @� @��� X�g�& @� @�F���u�_\
_�� @� @� �=k�,�D� @� @��(����\] @� @��' \`힥� @� @�e�Q6�K� @� @�@��ݳT @� @��L@�:�\\w  @� @�螀��{�j"@� @� @\`� XGـ�. @� @���v�RM @� @��2�(p�%@� @� @�{��Y�� @� @��Q& \`e�� @� @�tO@��=K5 @� @� 0���l�u� @� @��� ��^Uj"@�X^3g�\\^�r#N��ψR"@���Al���/�dv�\`�ŝg\_wb���uw���#@��v��V @��@�k����w�y}���:��t�I��+��ur����?"z�%��믿~оt��\|�i�裏�s�=�5�sf�u�jg�s��H���;�=�ܳ���c�}�)�)������p�_\

_�$��/4X�\_����S$yn�Լn��z��n��y��u�׼�s��9�����\]�=��ճB�@�fͼ�l��϶�E�B��������u?^8k�w{���=��v�����t�ڂ�n\[�5a�\[�J_\

_XG��4 @� @���vCQ @� @��J�v�&@� @� @��n(�� @� @��Q) \`�î� @� @�tC@��_\
_Eu @� @� 0\*��r�u� @� @��nX��� @� @�F���uT�N @� @� �_\
_k7�A� @� @������a�i @� @��! \`톢: @� @���Q9�:M� @� @�@7��PT @� @��R@�:\*�\]�  @� @�膀���� @� @� @\`T_\
_XG��4 @� @���vCQ @� @��J�v�&@� @� @�c�Q�: @� 0��͛W��2����M}#@��R �7����e���Ku�� �4�HQ�!@� @���f�\*���z����%? \]�T_\

_��uX{�e�����_\
_7ܰ^� a�Z2�5��~��˺�;�um$@�,o3X���� @��q�W\\�����;�, R��{���e���. \`�\[o�:T�񫮺j�\|���S&O�\\6�h�:�=�s�m{�GI�z��Y�fՏ�ӧ���ڪ���%�N� x @�@�\`m�(h @���4iRI@�Y� P;ˍ7�X�4�i���͙m���Y�u�_\

_ڹ��kl�q��رcK_\
_ @�m�\`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @� @�=# \`홡�P @� @��& \`mۈh @��;vl���{\[�._\
_"@��p_\
_��b~?\*F������ @�X���I��=��#d\]���\*�q�ƕ�~T�v�h��? @�K?~\|�x㍗x� @���'\`���7�zL� @� @�@��\]�T_\

_X\_��ה_\

_Gu���Y���Vo�q�e�5W/o<�UY�\\\|��G��{�Y^򒗕�z�_\
_{ϫ��p�_\
_�!/yI�9sfئ\]���u;N9����{�-kU3-y���+�R.���%^�;�����~����.(w�}O��˺�\_��w謹�/6\`�l�\]�S�߱�f�7���"��?���:��v�5�\]��}��ji����\]��?��̫��\_���c��hJ�<����~/r��I\_�j\\~�_\

_헶��\_/߯�^�Dն,հ�+\_Y���g��� @� @���&pKn\\ͪ\\�_\
_:�Rι��r𦫕m�z��Gl=�\|����՗?Myj��,(�;�Z\*�)�;W�R�fn�y�Ce�\*$=���9��2���z}��x�5Jf\|~�9�}{�S����&����栣���j���^5���_\
_y�w٬_\
_D������3g�k�v\|�����2�2LH��\]&�ͪ��)gU}\]c���\[��w�������;~�rf��Ѳ^9����3�.��B�yվ��?�x9�_\

_��/�pL�۾�\[W뤮��������r���\|�o\_^$P��E\|���oRς�lأ�kf)��YȗV��L�j�2��?կ���/\[V!j�R\]y�¿�;��g�=v/WU�ko�֗��\_����;w�mo��ϕ�gy�_\

_�����\|��_\
_<�\_\\ye�r��1~�+:\]}㹗\\�\]\]�-�ǻ��YZ�����V����n�m�u��w֞��������NWk�����~w�?���?����l����N�ǆ��\|��+����X�u����wL\_h��Ż @� �K@���ś��\|vg�������8�I�����=o�������7�?��k�^i������л�S�c�����<�����Vq�Go���q���\[�G���eC��J�Qn��ǝn/5o��:��\[o��37v\_._\

_�n\[a�d�2�x� W5K�Z^'�y�1�'����Z��W���;�p�ϳ��\`͍V7T�Ust�_\
_��(������������1uC됇 @� @8��R��z���\_����&����qz������\]\]V�=��i��t�_\
_���k��S^��wh�goZ���{�c���K�q�Ԭ�Tֶ�kU���ô����jZ��C� @� @G�_\

_Em�����赤���g����^Cyk�m5O�Σ������gv�uY_\
_�?I���h����C� @� @\`�\_�֨�V�Y����{�ok�Vz�c�t\_�g�e�dxN��g��lU�}i9�j_\
_VO�V�k��!ݛz�bϱ?�_\
_����^9_\
_�\]����ƪr֢�٤�/�ʽ\[����þ��_\
_��Ր� @� @�����R^/�E\_y�55��K}��;�UN~�c��Y��r+{��p����~TS-}M�,_\
_�<ٛ�5U�f�\|��׺�\[V��<��x_\

_r���\|��Zk��~j9���X\_uq��QǇ @� @���D��gsC���9皖m5\[\]?�w\]���t��\[k�fml���� �9��jsk�e��rcG����CMU��Ks��,���٨e\_��כF��15���� @� @X����\\�&j5�Z�ٯ���fm�����q��9s�q���b�5�\|M�k:��Uk\_�ŹQW�6jM�ړ��뽵G�����16��׈�1U���T�A� @� @������\\�폱��u���۟���y��5Y_\
_��'b��s��P�U՚��\[V;8g\_��k�f�Qk�j-����o��\|��\|ۨe\_�F��\*�߱u�٨� @� @X���\\�.j5�Z�}~�)^�eBy��g?�E9Ǯ�m�\|n����!X��i��k:��g͹1�{k�xeݱ�t��h���S�5� @� @x�h���oM6��a-�Q��s\]-�{x��ۗ�#�Z�i�ɮ��k,�� �b�g�u�ih�a�&?���z\]7Hm=ױ�F-��}Y�8o�L�\[˱�h���z\|@� @� C=8�!״�ۗ����z+�׈Z���F��iE�L�y���z���Z�U������l�a�{m�c��{^��s1���x������s�jbnȯ�74�< @� @���'6���Z�폱�&��X�/ݏ�h��X�5�'�~=j�ˣ�Ś5�Z�5N�����\`M���4/kZ׺\|�O�����b<�;/��5l�6)5����@� @� ����jg͹۷�\|�ю�s�ⱚ��s�n\_6�5�-}U\]���ɹq�����u\[��q���l�8��5��l\[Z��k�9Se���P @� @� pp �g64rM+����miQ��H�{�kX�������{^M�Z_\
_VO�Z07��Y��y�F���i����Vcl��U�b���\_\

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/GetCurrentUser.html

CloudKit Web Services Reference

On This Page

- Path
- Parameters
- Response
- Discussion

## Fetching Current User (users/current)

You can get information about the user who is currently signed in.

### Path

`GET [path]/database/[version]/[container]/[environment]/public/users/current`

### Parameters

_path_

The URL to the CloudKit web service, which is `https://api.apple-cloudkit.com`.

_version_

The protocol version—currently, 1.

_container_

A unique identifier for the app’s container. The container ID begins with `iCloud.`.

_environment_

The version of the app’s container. Pass `development` to use the environment that is not accessible by apps available on the store. Pass `production` to use the environment that is accessible by development apps and apps available on the store.

### Response

If the user is discoverable, this request returns the user’s name in a dictionary with the following keys:

| Key | Description |
| --- | --- |
| `userRecordName` | The name of the user record. |
| `firstName` | The user’s first name. |
| `lastName` | The user’s last name. |

### Discussion

Fetching current users returns the user ID and their name if they are discoverable.

Discovering All User Identities (GET users/discover)

Fetching Contacts (users/lookup/contacts)

[](http://www.apple.com/legal/terms/site.html) \|
[](http://www.apple.com/privacy/) \|
Updated: 2016-06-13

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Art/1_create_server_to_server_key_2x.png

�PNG


����m�        �@�NK���G��o�\
��1P���EW諾8��X�Ȝ�@@@@@@@@\`b�c�T��닾/�VS����@�;�l=3D����Pp��I�\_����7�c����߾N�KG���00���a(4��������������h1\[\_l9�\

�rO�vmVr'2+���r'sW:����,��        0q xt����ڝʭ���d�V�

}}}������ؿ~���kooo敉�U��t'�^6�Y��d���fNC�U�L\]�J��������,��vec+;X�7o~�?�����K}�}��?d

)$8E �K�vtt��OοW����h~��P�e�ʟ�ʪ��ۤ.I�j�����=��:���K�����z��U\]�enQS�L=��\[��H         ��C�?�k�󚔓U�~DU��沓��H���$��z����RwG��Y����Ŭ��!�"�����\
�}�b$��@@����~�NVq\*��\*+'�ȭ�,6��6���$�6\\eb�Ԅ\\5����z��6����h����yw0�:H         0 �e���d5����L�%WI�%��J�$7l���F�:\[�e��M�2�\*�s�"1pЕ�S9��������L�?4���Ҧv�����^vR���U\

�

-���P��b���;X����J,����Z7�m�޾8�ή��Z�O=�����ꫯf�L���N�Q��8NEEET\\\l�v4m�4G�V\_�Q�!���3�&�7���\_�İh��w���w����ߡ}��g-�F��ƶ��rW����OrqN\|M$�N\_����qjz ����\`��曇�DêU�\\߉xO�\_\\;��7�@� ������������aR���o��x����������Ρ{���{���6O��W���Ǐ۪���aľ$��v05x���v�9��+4���kδa��ũґ��u�.�۔1+�j�\|X������U2�UݜK\_��rUW2\]Go���Z\|��u D�gO��Q�<��-���g\]~U�d6���s��/����R�q�\_(���.�aK.��=��1X\
\[���8m�1loG��^�'����\*o�+���fϞ��˰v\_ߌb %%���}ƶu��܉�uޤ������?�s�9��n�����V�yKǫߦ-���#���\*�����.!�G��\]��l�\

��U�'������r1��v�i\
�:!��\

�q:�lZ�th=��\]F3�:魲m�w}jR!��J�����vQu�L��Y�y����\\K��{��RZT�g���E3�v�K�O�f\_DS�:\`���������ͣܕ��\`�\]N �w��u����}z��-�ŵ�%AƐ�x�N����d��<Ş��������O�2��\|f��.7�EWd��l\_���Fݛ�U�d���&e�.���ꪏ���u�-ZD-랥��x��8�Ló�U.�\[�"���E^x!igPkͻ.{���\*���ʻ=������Y)����\].{lˈ��?�b����������b���l�\_{�����O�K/�d�\_��\|MNƱ�Y\[\[k좕���B+�!2�WC� �7��~�� A'p��=��E���4���yITVY�NV�˔�?�c�k�htx<�v�R��ʗ=�&g��;��� ��ӝB����";���=;(�\*� ��0O;O�(ָ.�n}�܃�����ۏSo�LR#��'ӹ9��m� 02��㩹���e7BCC��\]µ��AƊ@0�ӄ��'X���e0�l5߶�6+�W��9Kg\_��◺����)����S��4��;�D\_%���\*�JO��\]�
9�J
�n�

�wGB�s\[�tza�J��f;��/<���<#�F�S��֓�ZH�~���\_��)\|����r����������BQ\
\]qt--�\[k�\|0�3tAXut��\*����?B.�@�E@�կ��\*#���ŋI������v��E\[�n%98Wd�3�<�zO�娃��X��sI}Ʃ�n�\]�vzVr�c��S��-�)\[---��@���R�3�;�{���v���s�C��@q����KP}X\]\_��\\V2��6l�vNV}P��\
������(�9�nۮ����9;Q�.��HAH�D�\|#�<��,(��\\���d�\`<�� =�Q\*K�֭���\

'�

~t�}q�\*���꒛�G�Y.uIv��M�N�r����ɕCV���l�EW�T?�         ���%)��9��EMW�)��+��̓�YϽ�Uo0��zYEG�\\�u�^Wr�\\��@@@@@@@@@&6+ߡ�LQRmz\]�f�j7碧�^��n�dU��ɇ
00�.��z؍���~v����������������t��L'�~GO������t�{�+���=$��K���P���\\O��JW׳++\]#��d�h�(��\\���z\]���+�9W:�A@@@@@@@@&&��P�+"�Lʒ�rW��v��1'�ܣ�E�y�JE��u�\\ڭ�������@@@@@@@@@\`b��'��1
�G劘\]�,W��r��IC����u}���A�vO2�ϧ\|��9t��Ҽ93)-5���}�+766Qm\]=�ڳ�ּ�2�عGoF@@@@@@@@@\`t���z\]f�ץ�o��.��&5˪G}oNVK�6BH%U6�\]�\]��L�6�yxx8}�{麫WSH�ٴ��

v�^��q�qN}bA�~})������������J.6��U\]d\*�u
���E�91�)��Ve\]��e�ҳ�SS�-垄uu��}�v�����f���x�� � �۫:)�/r�<Џ���H}7�{��2b�yg��RKr�o.m3����Gs?�/v�@@@N}eMݴ����.=�����\\a=�

��(���
�RT@W�\]L5�����������M�\_eĈ}��7�\`r.}�;���:��HX15�n=���ۻ
�W;LN���.�

��+;Oo��r�������7t��1�օN 0� LɈ��ΛB�o:Fo��2Uq��{��ɿ�sj���NI����s��yn��N=����y�R\\T8}��ן�x:=�v/U4v��S:?���b&/蘒g?,;�׊Ł�7SS"i��/;X=9W��H?9k �\|E8���O�PF�q��o��9�ѕa��\\�16o\|���}�=ɷzKg�.�4D�h�?�9�'���

ơ�I���9�9w������xױU����@��J$Ʃ��a�׏4Ӫ�Á�7�3���ׁ.���j�ׇ9�p��\
��5�y��\]�f=����P�\[t3��#�F$\

���X.WE7�\_��O����Rm����r㨌wĪ��k=��M��:׫���������\|���m����Ngf9��sX��I���k�ݾ�C������O�)%��D�\_;�������0�fӦ�n2"�k�1�8�g�鄝��+���\]g\`GG�q�TTT$���ў={��R��p�4�4)�$�@}}�q8Vy���!V��\\o����(̞9�����!����iێ\]��??A{���\|��C�eW��ɹF��R��cgΘJ;v�W���!��1��a+I�o�=t����޸�.Xy�'�iKұ�eC����T\]SK������5<<�������+H������8t��'\[h;�ȎRq\
�cǲ��O3��\*ޕz����������t&;B��4R�\|\*��v �D����\_I��b���!Z��5t;ku'��"-�i�\

�Օ�A9����I)��9�k�)���TB\*7������k\]2)��6Y\_{�=�4=5���\

\_ךǡ�IS��G�7ި�\\�M��a4S���yӏ'Ǩ�y���V�VY��������yI���������"7?ef�;ճ�k�<�ֶ�e��bte�:N�t��@v�%p��vZzJ��t��i�������)??߸��SOm⸔\[�g͘Fn��I�h���UU�yS��A\*��I����76P1�2�ï$}��NSww}��6z��Ͷ\]�h�'�U1\[ue�������'��A���v�&ݎ\*�r\|����\]~Ʌ���W���\
��G ;9�n�����slX\|TY��P���iq��(�p�����,��\]���8��=\|�+���p\\1=�����w�F��1����!��@����;Y��\

�a��q��Hs�q<�g�/3�t��6�ݟ��e\|+��^P��E\_v!p��Ξ�a���\]�y)����ʜ����K��m�&����T��:������4��\*\\���8�\_�Mu-ֻ
\|� ݉M@�qR�q%);E��1��'��Z���Zv��$��X�\]�-�kDvĞ9�u׀�u��������\*�H�F�V#�<�\[o��W2���g�S;oy�LZ��v�Iۓ����<��5�n\]�1R?���~�a-�͊"'�x�����&�ɟ��a�������~�����(��Ň��b��ْ�uq;���{���4϶L}9�U٤2�\*:�yJNt<�w�
��v�G��H@��\]��8,(��0u�$\\���\|V=;<��t������x�rp���͡

͏2�տ(3v�m,ʎ��s��N�۽���tޑ���v�.H�G�r�\|Д�� c��\]���O�f����D�\
�a+I��붥�B$�N^Y��$L%��\]I���0�F���.���K����~5���k��N+J�{a��~�h��Y�k�y�ĉf�/��U���\[���Q���j��������(�� �~�a�W����\
�}�˪���Z�A��j���v�ʀ��J�z����L�s��௼V������������@m\|���\

e��:ZR��!��Fq���U;��Q�۰\*o/n0���@����8N���5�nS/�#N����r������/Ȣ�ǲnǪ\|�o��\]�rk�\]����g��j���\`�w��Z�WvD����F���\\8��Z�u�r��s����i�Q{͈�����a�� q\[cmn32��A@���n�/q���÷w�\`G��A8u����2hgM'}s}����juM\|W˷�W�/�U\_�w��V�#S⿚��ہ& #�K��C��{���4{I�\|���fq;&��3�P�Xk����-���<% �gu���G�돵�\*���\_Q�<ûL���U��LؗI�zY��S������\

��}���z-~���zr\*dddPl��o��!�^c'���������gt�U���$9��������\*���om�u����X��

ݳ4���{ ��\_�f����C�i��Օ��˲���+���!�C�8\_g�J�\`�h�����SC?�z ivz}��,����?ヶ�?=����\_.�s��g�$�s��~�ƇF�lu��\

.���ސ��\*.��/w��uƤ��C�F+��� ��z��m��� �@�6�k�g�'N�06�ӷ����\|��8=��k����ҏ7���ʣ�)�K�

��Q�ɇ\\}�c�J�vI�q=�A�/z��i<8Y�$�+��\|��Е�/"��:IƛH����! 5��g\_�=�L��c� ���y�����)���tH��N��\`kE���\\9&��NU�
�/f,@@@\`���T�7�I�m�����\`\]'�����8�AR�\[˻\]��9���ڔP�tG�m<9YZ�������^��^�'��Y��d���~��M��b� �����@!�C�������$ ��+I�˧'�\`�<��v2��4��~���M��Vž��         B����\*��C����?�u��AW\_q ͛;��R�)))Q��J��MTˇ\\�޳��<�����4t� D��r���Mn�h��#\]�T���E��@@@@@@@@@@�NV�
@@@@@@@@@@ p�\]A@@@@@@@@@\`<;YC�������������q�/�NV�z@@@@@@@@@@\`���u�?E� ����������x&'�x~v07�qO \|�ϰ��f�O�� I���aB���� P~�\|$��&������(�N֤��QB�a@��(?N��Nա  ��@Km5e�d{�@������x'�p����@@@@@@@@@�58Y��ӃɁ���������wp���g���d�O&         0� ��:ޟ!�@@@@@@@@@\`\\8圬�����L�Q���##(.)�BBB,�!��H 6&���'ⳏ5�����J �=D�򳩩���ٸ��墋VЁ���XI�\[�������%�S�ɚ��Is�:�����.)��iEtֵ�SMY��;@��t5�55���=u����e�� z!5N�~G��{/�F�55n���6ʛ5�p�fO)4v��tu�g��ne.�%'֖�ʟ;�����ތ2���:�ٳ�P'�\`�a�V��%KgӢE�h���4�)S󨮮i���'#6�ɩ�T��=�N՘�(��J�c�\*,g)�M��G�K\*����RB�S��)�d���6��(�-#;UO��C�  0"�"��?��B\
����(11ޘJtT$͛?��3�����,���\

��cWVU�2\
���kj�~���9��@���I&�:�f˦��(�fO�٭{w'����h � � ���X�h��L�)w-���k��m���+i3q���z�a����^p�X��\_���#�N�\|'��W���q�8uN�9�z\]����RVXd뻎�:��u��Y��5����h��z�����\`�x�A�ƇA�

$�.ON��g����'����)W� ���h֫<�3����y\]\\ � ���/@M�;�r � � � � p��F\|� � � � �w�A�;�r � � � � p��F\|� �t��w� ���\_����/� ��f��L�k�������좲�X^�����@@�Y{�\]�@@#�����Gn�EyI���{OȤ9����\[υ�#� � �UY�J��"� ��Yྦྷ�#/��R{�涜Iia���w��K����m9� � �@wd�e�� ��������F��?�}�G/ˏ������V����)�J;m�?�k�ly��۾��������'9g=������}L�xL�<�7�j�+������������@pQ�e���~�c\]�ٳ�u9��&�t � � �-Y��Np � ��-�+O}���o�-�\
���+rb�&���!��F�H��˯�������1�d���\\gU\[S-��Ɂ��\\}��j��\
V�^N�����7UM𶺲���N��ګ����\\�w�����I�勲�c;/\]H���(�8���@@� ��u��B@n��ܻ��������c\
�j�خ�e���s��s2��ٓv݄�k$q�;�\|�T�.������ßھ�}\[d��{���g�Ɍ\]���)\_�\_���� �~\[�\_��Z�a�T}�\\�r��ק�\\:R�,{X��~"u&����we���sm� � ��(@���\
� ��b�'����mS6�kϵW�ŷ���x�b�����\`���R��K�/qS�˔yw�Ƀ�ʵ�:��zD�����5f��K��\_����J�lx�g��Z{�?0��xz��k���mF��K���\
&8{MN�\* V��g@@o��Ɠ�s����or�\|��&}t � �=A 4b�\|���\*��we��F���pSJ@�3�z@��\]�y��Q))ȵ��GO0�9�Nj��75S���F��̳'�J��9��{�OJ\

-S����O8��w�\
����N/��)y���.��Qv�� � ��,@&�7��\

��g�o�����\`\
0֟�ϐO�/f@����;ٿy��2����#�K@@n�@�\
��z���Q����3����ԛ0q�L�x����}~�����K}�@@���z��\
�HzzC�s���2a�Dٴa�HDD�h R��ǎ�g���͟'�6n�l�\

��A~�WyUF�����\`��PW�uŘ(��$�Mp4�l�4'��5Xj���X��~��g��.�5eg�Z+/̔�Ss�RY��7@V��d\]m�"��������s\\�@@@@���AV\

��2�fu:Vg岲2)-)�ei-���\
W��Y���R~��\_��ѣG���ǝE�w\
�^�&5�DM2%�����\]5�M@�O�1��;�v�\]K�5\|�ݳW�\]�f��qqq��ͷ\\�:w�i��gL��\|�N{\|2�}�k�\]Rn�.\\�Y�z���y�@���Ak������M�����Z\]g���5��ƜRi2���A��lUm���׳G�c���^�}�%�\`�@P�\|�@�
�땚��)&���\*2��

,�9j\]����6/^�/
L8Ȕ\`�)=���������5�U盒�L$\[6���۳��P}5n��NеL\*L}��&��MK �7�N料G��$��I�a����{~Yq�����\`�4����n2k���\

����U;��m��l�����̠O�2x�\`\[�����t����<��c���f���5eE٬���G�:��}Nv��3�\|���¾GDF��aR��\|����v�,W�m��Q�c<�ՙ���x�b3PW��0��m�ⱛ�Q�\\�΂�Q��%�Z��s��+�Сr��e��޵�"��o~CM��Z���y�}��7G.�����\]�qb�Uuv^�w��X᳙Z)=h�O5uat���'�WL�����:$Df�G�/��ִ��fH˩��b�!�L���w�(��3���"3P�PS����j2h���y��7�J��L�5L���L��\\a�\\(�<�\]�� �X=�GfG\_���z�7?�ܿ4��X@@�.�$8�dgH��D���pdϼ�.�g�5;���6�@\[74=#\]�.\_&\[6o��K�Q�y��I~~�̪�Q��$Ya�����&s�!;w�\\IO�0�\]�������OKFF��ճ֌�+V����٬��D�?��"��^.�?�Ht�\*m��L����N\|����^N�J�{��k�O
0���f�K��m���4�;�3X�;\_ZZjJ?���\[ ��}��m�۩� ��-V�����G�uP\*}�߽�/��:D�h��E��S������l�3��&@{��i\

&��i�w���ǧ�}�f����z�ղ��\
v���\
y��wd��2w�<�2ٯ$11Q<����ݻvʒ���\_\|�/%/7O�#�$�J�\
tN����6�LNJ��3f��mۚl�k�\[GU�ᨩ��t�ۻ��Ϻ�m�Ǟ����������3�;����?r� ������Cm�R�L5{�ϩ���ꇫ�d���n�נ���3��gUSG��dc#�$�d�j�U� �ͪ%��1Y�m��&(��Ù��y1��ԡr$�LRr��u3��J����)���l�ׄ!a��t~�d�e�j�Y\
�N6�a\
�l��\|��΅� �@c��/ � ��~���tֽ�f�Gڼi�k�f\_nܰA�D@d�H �\

���d�4Y���7\_C"""�o߾RTT��������e�e�(�ɉ�q\[2L\`T��6��K&S���J}b�\`�e���1��̀WN����j��0XA�2@IDATu�s��T&8Zh2aSM��=�����Nl�������}�j����(�u��W��r�to���ٷ�8SP!q&���K��4@@@�YY��~���I�ZӀh� ������<&����r\[�u��͘9C��X�������k�OAA도��o��G�\[�O�x�?�}��:����ǳ���22,��H�6٦�߸�����2����\\u���T^�����.����u��R��a�� W�M6땊��5e\[k��@X4@@@�y=:��r��m����E\_��%L�q�Ɖ@�ɔ��}��\\3A�t�G�Y�ۺ4��\\p�ϧ� ���A6�5�a�e�\]���N�!� � � ��-��A�\[�Ďn����$++K\
M}Y�q{g�۶�l�~��"�ɯ�hO\]k��x�R��w�q� � � � �)@��Ӄ�.(++}�Բ�Fnoi9��Ie&���f�S�.'���bq՝t��+ � � �t@� k�Xh����~꭯i��� � � �t�@��;GB@@@@z�A֞wO�"@@@@�F��݈͡@@@@@�� d�y��+B@@@@�n �ڍ�\
@@@@z�A֞wO�"@@@@�F��݈͡@@@@@�� d�y��+B@@@@�n �ڍ�\
@@@@z��oϻ$�@��gΜ���"� ��H����w\]Y��VVVt�Q8 ��&��C�����Z@@�j���p{�����(��(+)쾃q$@@@@������7��C@@@@� ������C@@@@/ ���7��C@@@@� ������C@@@@/ ���7��C@@@@� ������C@@@@/ ���7��C@@@@� ������C@@@@/�����������w����5� � � � � �^2Y�+�z � � � � �@3Y�A�@@@@h�@�/7n��}�^\
\
�0��'O�o�׬����hGYY����9s��Ƕ� � � � � ��@��j���u�Kz�%�\]�E�R\]\]#�\]\[㺬1�#��?,/���m�@@@@@�z\|�U3X��\*�\]�����880J�n���b�u���MV�@�����r��U �>}�����@@�@���F�O���wٲ��p�!%PJJJL&mU��#� �7#PSS#)))R\\��ԏ����7N�r3���VWW��˗%66�C��cǎ��-���@��HJJ���<����#F����\*���2f����q��5���&2s�L9t�>>���.�)�6�y�D�f�~���P��\[���Cʖ-\[���RY�����{���2:v������ ��6�\
�-!�Х˖�r���;o����m�����7- ��4h�і�}YƛȜ�~m��\|��\|\[\|��a�dQl��e�%.Zh�\]��������.c�����.�G@��8��!�û�lpp�}�\_?����骏��r\
h�3ly ��u4��5p�M�z��׬X݇�/���o�����̙�=\_����J\
����˪��皾k� ��\\5j�\

&h��Ru;}�Uכ={���5��4\`����^�Ǵ\_kjpA��ݥ��j���iF�vTyG��ПQ�sO릎2��ͩ}�٦�3K3\\��ZXX��������\_Di��yٞ���m4��O��gD��?5���/����%�~1��Z����=�b@�\[#о���X^��\
��K���9cj��9r4Q6l�֤�Vt�/�C�W���1���1r�$LX\

�2}�\_�լT͌� �ro��\
�E�5P�A\\��4S�PKdu�L#�@WhU��w��?��&th�i�ܧ?���~NIJJ�ݻw�lS\

h�T��w}��������ΠY��Ə�.3u�i �@W L�2ŵk\
��X��i9�\*՟o�?�tZkJ��O���������%�-\]�ԙ����V���mq���X��J���po˗/w�e@�z\]�Um#�ceaa��9�R��1��ka'��m�/��X�x����x\]��ܳ{�<������&����1���:�&�T�kܴ�i� Z6W�L��\_���ǽu&�\|�d���A��/��\*sL׀\[��n�t�����T3��dm��t\_�mlEeE�ݶ�L��k2e�����1�m0{󦍦lZ�}ҁ �7��荞��40۸��5�t;�u���R��:L#��K@�-��j��#��u����V���Z�oJ�T���r%�%��B�k�4A^�8���a͵��m�x��%�/6%!\

��4
e� L�@NŦ$A�u�X:X����C��O������H���g�˙3�۵�����d�6;Xs�k�L�b+���d�6�O��

�j���7uh\_Y��kki?m��u��6-9����G@@@@�-��m ��C PV�Z!�

h��?re@j6�������%9��N��ZwT��t�}fp��f�-mӦM���r�i���U6\[���3r��)3@����g�)�g�n9\|�dgg���'jkk$99�pkm0��ُf��5^�Zc��L𵬬�N�o�����3��d��\
�u��\
PV��޶u�ԙ}N�<ٵI��,IOK��h��a�Z53�����^N��\

pjM��V�jx\[�ֺV��3�8��l����mgN��Z�E:y����f\_�\]L�li�jXx����xD��G�w}d��VYQ�d=��y\
l�l���I())i�m�?�ԣuZuu�3�z�R�L+,,4���B����葦t@�G�����\]�{���U�=j�:������׽%�g̐U��2Y��&38˖��BC@@@�3�v�}������ٺ������ٽG�~�i�ȼ\]��z��L��ߣ/ �!3գ��h=ת�jW�ŋ�@UmR�'g͞)=���������Ը�c��&0�ARmכ��c�@�E�8�ٳׯ\_��\]=VnfFK��cs-��WVT4���%%��%4�?QRR<3R=���{WUUɧ۶�XRA��u���\
���s��60�y�Fw��; � � � ���#��y��u�E�Ev���� �uL5���Z��hr}Æ\
��6\|����ے����y��y���2\|D�v��G�uP���J� �j-�1cƹm�09��#M��Ф����\|�3\*�Ԍ�k6���z�DIs�ˍ;�.sorK絆��Ǎ����ki�ս��;�\\CtL��Z�v��,vL��{��n5�8�d�?v�86��� � � � ���%@��Z��Y3���q�����t��m��ɕaÇ�z����tt��F��%��e��v�Օgϙk�Qg2"��c���-����UU�&۵�d��� ��4�9c�L9v���ծw�9:t�P׺���ȡCG\\}�����U++\*%9)IV�\\aK(8��/8���8۷�\]�O�J�{��k��m�W�m�k��ON�V\]��\[�qZ�t2�CDD��K��3g�j5:ֵk-�0������w�1� � � � pg ��r555f@�@�4�iw��55W;���6\[�l1��ϖ�� W��Za���H~\`P�$%&ʁ����W�SG��/���ݩ:���:��M0.Ƶϴ�4,���������LY}�����s��{�N\[�U�Ѻ���i}� Y��Gv�\
���o�#+W���@�~�����^;H�kG�صc�=��EU�v���κ�N5Iݵt�=�k�����L�޵�f�~���/!��6�uL5볫\[rR����}۶&��̼l�'�ʳ�%)(�oֻ��@6m� k�\_#�e�ק�\]O�A8�f7\|���;�%�/�¢�}��y\`NnrL:@@@@�)���T�����u��y��LXg�3���Ӎ��xN��;���:h^�g.\\�4g��=������!{n�&�-Y8OF�&����Ggg4�e��hUU��{�e7�gfq:�}KM�׿���Vk�j�l�\`\_��i���ؔ6��:Ҿ��o��~���񪙛��Yd�������USs�nl�ut���Q�k��a�xyWͫ���W\_~�����6�,L�o�j�\]�Q\[��w�����5�i�x�L��b�q"^4s%;S��/:#N�s�R��ٷ���h\\��;\`@@n�@s�"�:Szʬsż4O�e�ҠZ�w�s��i\
R9���N��7�v��"���ӯ���3Y?ٺC��%�"�N���vfDj���i�dт9���T������CQ\[�4����r �}�A�Vkk}^\_7�4c��֞��4�\\����n�dٌ�3LF��V���im۶Ziii��������mu',D@@@�\
�d��/�\_��UYy�R�g����k��8w!�n�\_PخmX����0Mƍ'����O�̋�@@@@n�@����Io�����Ny��Y���3�ŧ��\]8A������;���ԔT��h � � � �4'�+���\]8}�N ;;����6쩭�\
: \
@@@@��t�) � � � � �@'�v��@@@@@ �ʿ@@@@@�&���"� � � � �Y�7� � � � �܄A֛�cS@@@@@� +�@@@@@�� �zxl� � � � �d�� � � � � pYo�M@@@@@���@@@@@nB��&��M+++��8@@@@茀�Y���;s\]l�\](PVR؅{g� � � � ���%@��;�~q� � � � � �eY��p: � � � � pg d���g� � � � �^&@���n�� � � � �w���\|ugqr� � �@�����ȬY�$,,L�\]�&'N���W�ʌ3�\_�~���ݻwKtt�}��S�������Ș1c$""���gC@@�\[�L�.�۷��D���/1�.�e� � ��\`MJJ�%��N=&&F,X ,ǎ\

��S&���="�~��\
�\

"\_�^/��\
�惌f��?V�n�ak�\
7ֵ&@@��\
h�S�fdd�Sݏ�(0O\
i�U���f�����f��/�56//�\[;zl��is�̑�#G:��z�gd�ڵ�����۵+!� � �Y���1h� ���~�~k�/4��m� :\`��A��9�Lk\*��/�F���6 �~�p2M��2S�8�m�f���v�\`S�u��ard�v)/\*��+�ɉm���\|&�Xk5s$�\\:}�e3SO�yLV@@Z�0a�DFF�kJJ�̞=�P�����q�����X��T� �c�:���sZ.@����ʄ�}0�Vg%�@@��=.�:m����9-45YOl��^)6uQ�Υ��5�u҂9���i��=���2.��g꫏�� ��H\]mè����g��0�X}��J��\

�.\|�;\_w���m��ط�\]�gY�U�^����K̤ rj�!g5�@@�Nhm�1c�؁�h��: ��˗m�T����i6��\]\* ==\]��Aې�;����---͖+�H��n�@@�F�dm�./3˖ȹ�a�\*��3�����n��7�����\]D
&A�AR�٠��?�Ro&�u\_�Vc�^HL��w͗2�xɕ\\j�Cccd�����O3N��khd��}�c3�;D��ꏶF�n;�汞3�OK�R�����L�?G�M�ҔpZ��K�Yc&O��}�n��Y��'Oy�e��5�hM�(S׵�R��2f@@�\[%����ѣGm�V-/@C@@��hцB\[\

\
��I����)���2/}�\\\_�k��}��:�� 9���N��7�v��"���ӯ��k2Y�՚��TVٗ3��������\]�o�� �x�@g�\`�����@@h��f��@@@@@:)@���pl� � � � ��AV� � � � � �7!@��&��@@@@����\*++�K � � � � ���\
x}�5((�k�81z�@YIao�t�@@@h"@��&$t � � � � �� ��~+�D@@@@�dmBB � � � � �~����bM@@@@@��A�&$t � � � � �� ��~+�D@@@@�dmBB � � � � �~����bM@@@@@��A�&$t � � � � �� ��~+�D@@@@��6���C�����%&z����Jpp�TTTJIi��g\\��ɒ�����<@@@@�U�&��?2BV�\\.Æ��'�d��mRTT,�U(��G��qc䋟T.g\_��fy�YNC@@@@Z�Aָ�����5�k�yc��r��5�Ҳr�WZz�\|�m�̟;S���������̹�2� � � � ������Ə��W^G��;�$�d�Xݛ\`u��\_{�n���@@@@@��zt&k�)�������l���g��s%22��d=u���ؽO\
\

���{ 3�ۀ1��� ��L7M�6��?��Չ�6�/��i�&m��qb��x46f��,��7�{����(�r�t��DW�����9�9�y�9�\`���~ϒ�KM��zٻg�����Ï����,ٴa���:~�xY�Ѓ��啦�k� �F�q�&u��={��uUG�i��\]�;u�T��\[�f�J\\\�,Z�ؖ�k\
��W<,�Ξ�WW����Z��&w�����\_�˗k��Ѿ���y���Y�?f�7��=Fƍkj��ܜ\\?a�L�i��Y�F��r�͜�s%<<�u���s\

���ew7�{w���tGbb��4�n�vCC�G�fӃ�viC�U�}���5�F'�l�yl5ٚZ�t���6;4ڔX�h�-�t��rW�f���i����

�d������C@@@@���6�z�\|u~���ҥ��l�
��iG���魍4�9{�ۮV�U��\`���E�S\]�t-C󴩃�
^�d���)�-�O^y�e���7��b =�f�v�im�#G���6Ȫe.�2��}\_-�\\����i�Z���c-��m�n�<4��K����ӪM����

\

�����%5%I�O�,#G�/�ү����JYy�?qJv��D�s��!H?$�+ � � � ��� �C�Է�y��d� � � � �tH@\_���������L~���}�g � � � �=Y� �u��f�vV۸a�:x�N&��ђ��!�/@v���\|v��TC҆HBb���7�\
�vU�sᝲ~�z����y�����}j����IJ.x��@@@@�wt^�wxܰ��l2C�SP�/'��G���9sN\

hg�)70l�0�͌�-(8H�g�-Gp���S&''��p���d{�������uն�.���\[ii�DDDڮ��dT��{�\`pYi�)�����: � � � �\]\*@��.�m���1�&C��%-�ٞMg(/+o�e����#S�N��#F����l���<����:޳�sb�/�\*���+-��ޚ�ǚ��N���쬺�W�֋ޣ6͖M�(\_x�I�~gE�ܨ��sN� � � � ��-@��O����͋�

�d�6�n2T���Z۪͋�.�r

��\|u&�z��ȭ�3%�RX\]/\`M��q!2!9\\���'�D\]�l��'@����93 � � � 0
�N�/����ɬ��74J�����&��l���\|�gL�,-\|����

��1�.G�j5����

n�@yiэ;gB@@������2��=�\|^���~�S5)���S��޺(w������yFv �5��WfE@@��.\_�,yyy���
�zU��y�VWWg��y�5�����ƶԧ�XVV�1���ڞ���ܣ�
@��#���JY4�E}�\`�Z}p�JjM0�d���9�f��f�MfN�(@���
ׄ � �@+

d�Ν��7ʦM�D���kUUU����b�C����{�S�z��N�r�����-\[�����%$����\]YA���}�sx��{8eJ���w.��y��5W�����dG7�������@@@��3gΔ��$������xJJ�\|g^����9�c�wD��tN�(@���

���Mh�wŜ���C�\]�r��#� � ��4\`�V'H�5O���Ӵ�jii��i��U~
hj ���Fv��!�to�������Z�u�F�:�3f̐#F��������u

lf�f����6����\[5�y��A�"+���4���\[�F�@�M8�\
��:��2e��g�{�Χ��:���eZ6l��X=&55Վחsi֭�\[g~� ��!\`��'\*��-��~e{�k����+����\*��v^.�\\g�Xo��9i������T�&@@Z)��-5�՗ai�R3F���l���\

����uL�4Iv��m��n9�i��6}�՘1c�\`u\[�E�%�@�G��#�����+��O�kv̓b��/2���P����?k�}�̱��d�!�����^���Iu\_꺷m��lp�;��K\]o���s�u�l�/u=�\|�3�,z�,i �G���ẹ?�+�R@��+p�y#���z�\
p�=F@�������\_�f�j����S���Z�V9\_��5�-�UUU��Xz��M��ϟ�E��:c��xg\]�n53���رc�����X�#��\]���#5@��\
9��8���.��������;R�u<���ɧ͝�O��h�#�4xYj�{��돢�������gv�}M��~\]�\`�\] �?�(��d�@@�w

�.Z�X����r
d@@@@�

M3Y��lf��T<$so�'���RZZ\*�ӧ��s�<�Y�dI�� �R��4C^\]�RJ���T%%%��������?����sN�@@@@�\\�Ջ��u�?wAn��T�WȩS����9������ۻ���#"$55�d��Hhh��W\*��w���Ǐ��#F����dѠ�\`u���KYi��3�uNgK@@@@� ����e\[\
\

��������l����""#L 5Qrr�����\|���/���˕���T�����.;w\|�\`

�Ҭ�����YG@@@@ �zu�՟�~���A2-s��Nu�-22R.Zd^tuZ���m���j֬�%$$�&C҆�r�UU�X�2hP�k���j���L�������{��@휹sLm�-

�9���N�.��;}f���t��ץ��L�g������~�G�3�ЀhaAci���WXX�u���HOϐ���ɪWW��uզ/�6,ݖ&h:�r�rM��� � � � ��zu��3�� �s��#GL9�a�ȊGL���&�d^�5�d���'����EsU � � � ��@�^d�ϣ�.Y3\]���\[���\*I�I6�uǶmr���N;!� � � � �@//���ɶ,@@@@@�k��S4@@@@@�v\
dm'�!� � � � �\*@���@@@@@�Y;�ǡ � � � � �AV~@@@@@�d��"� � � � �Y�@@@@@: @��x� � � � �d�g@@@@�A��q( � � � � @���@@@@@��8��ZUUyC��I@@@@@���}�5""�=��1 Ѕ�E\]8;S#� � � �=K�r=�yq� � � � � �gY��p9 � � � � г������"� � � � ��� d���� � � � � �@� �ڳ�W� � � � �~&@����� � � � �=K �g\]���v@� ���9�w��y�}����$4"�n���Iq^��߲C

��Og�Ts$�=K\
%y� �����\\1�紺�Z�x┤�i��!!�w�L���U���<����9S�D@@@@��5A�(�r��J �s�=2f�t�jJ?��L�b뷺8w��3�Z�9n�p��m���R\]^)n��m7} � � � � Ћ�{˽\
5/��()�5���떦�1O2Lɀ#\|l�BM�i�y��f��<^���d�����X\
�'çL�ͯ���׆�0k�����=�k� � � � � �KzM�5}�9{���c:w�y��dI0����ʴ���:)�˗�\_~Cʋ�=�i��7�\\�KJF�}AVXd��~\_��9r\*�\

@@@@@��Y� �a � � � � ��
d��@@@@�A��q( � � � � ��UU��~�\\ � � � ����Y#""��p���@yi�^W� � � �t����S"� � � � �@� ��{�%w� � � � �� @���9% � � � ������Yr' � � � � �
Y��S"� � �@� ���u�\\- p��F�;��@�:�� � �\\O 99Y

�^�� paaa�G�t������#� � ��u"""$--���� ��)@���\|��5 � � � �t�A�N�d@@@@L����ܹk@@@@�$����4 � � � � �Y�s� � � � � �Id

5٭�M���M3p���ܻK����JC@@@@�� ��r\\1,\]&��^E�I�%X�+�'O����E2g����V+�9u���^FjP6ch�K7#}�$%%���G���Ӣ���բc�d��^뾖����$$$���n���$�\|����e@
3/�ro�����e^��¬f��@@@@@�c�.�:n�(�6e�K���N��8%G�����J��zϒ�r��%W�Uk�{��X!o��N�
e��d��2j�0�,��:릩&�yYΞ��:GGW�����M�R�^�Ҍ�~H6��Y�\]���?~�1��1��$�z=!�#� � � � �:�^d��/���7m�.�y��4 A.�UFO�=��ˆ?g��~�r�m���DΙ ��{o�d�������\]6 �\|�?�d�6
�N�8Q�M���65\[�9�\]IL�� � � � ��x�^d��~��һ��Æ�Y��\_��}W�u
������3�=,G���Y�Q^xiU���ձw�^Y��Crּ�+'�1�5..NfΚ%�V����xIH ��a&��ƞvh�P2d��jՠ��,�� � � � �7^��Y�j�֙�+����O\]\_�o:�۶����.��W�h����tV\_aa��\[�F�,\]"��7��h�u���RZZj?�ϟ�ǟx�d�^2/芑��2y�Oo�.���a����a@@@@h�@��FFDHee����6���¨�&/�j��ƾ����:{����7�ILL���b�uuu�q�\]/���m��ԗ����������Yu-����Zw\_��\_��}�u@@@@h�@����\`dYy�\|�\_k�i���4C�W���4�J\_��G@�hZ�=�n�\[E����ÄL� �@�RSS;t�?�냬�����?�sM � �@�z�/����@� �V���0�"� �@���j�@@@@@�\
d��B' � � � � �:���sb � � � � �U� �W:@@@@@�� dm��@@@@@�Y��Љ � � � ��N� k�� � � � �x �ꕅN@@@@@�uY\[��(@@@@@��AV�,t"� � � � �� ��:'F!� � � � �^�ze�@@@@h�A��91\
@@@@�\*�׏:�K��j�@@@@@�S�i��x^1\[ ��G���k�@@@@�\\��< �@@@@z�A��ظh@@@@�����$�@@@@�Y{�c�@@@@@�\_��˓�:@@@@@�G\
�ȫ�@@@�(PUU%RSSs�ʩ@����D�������\
�B��\]��� � � �;rss%\*\*JRSS{�\
q �@' ���������I32\

d�566J�������D�ť��^v~�G~��祤���v�C@@@@$ ������e��Q�٫�ѯ�̝}�����מz�@@@@@��W�u���ȘQ�-�\_\|�\[�p��~�nk��!� � � � ���L�G�/�/<��8�X���kםm-����h}嵷\[k�8@@@@\`��\

\_�W^{�֘�j��5�Xmz\\K�� �@@��fݸq����ݛ����u�ۚ��i�����5�ݺ��Z\
�5JΞ=�\
Ҧ���رc\]cYA@�\[� �y/���\]��M'��I�G�8Wll��Q�,��)7�\\j+\*.�/�{�ڻ�Ԕ\

�j���HHH0�\*H�6} � ��\

�'��"� � � � ��\
 �zC�9 � � � ��6�^duj�:����@@@@�^���=}ןݩ����<���?��3<��#�������� �E�RPX({w���<׾�\\��������異��3��ֹRSS���\]�\\ӭ���@@@@P�^dm�cv2\_uy���49n�\
r��!�&��ђ��!�/@v���\|v79�Mow.�S֯\_/9�9�vӇ � � � ��\

�2��M���U!?a�,�A����\
,�n�/������a�G�2\|}��%?/���7Nf͞e��$��%�\
�ٳo�~���������{�=�w�z���%�{5�9r�HIKK��շ��'l�,7͘)w�u� ���;��X\

Rg��y���m�����=c2L���-\[�l�V�g�.��$�N����";������2\|�p;Wk�):&F����\
���=v����\\

@@@@?� �?=���J����V\]\]-��W�\[j���O��O�����ʽU����A�M�h՟\_�����P�d�Yǌ'�\]�bu������\[{Oן� � � � �����(�\]W@\]���ޝ�KV���\_@O4��<@��< 2�e4"

=�\`8��SèQ������/̞=;�V�E\[�?�h8��3�s��)��jc�뾧:��\\�Z�a��ZǊ9 � � � �C/0��/�����Y�\\\_nu�)��T��QK/ .\
W\|��a��W����0�k�\
g����ꊕa��� J��q�}��zۭ��N:�x^�5k¤I��\]w��<}���o�~��E����n��ua�q��/���{����V�y����a�~z��~��뾧:x4~ ׉'�T$�/��\[u�0@@@@�!�I�!S�l���\|'-͙3'\\��o�q�ƅ�#G������Y�/��η//��n�mX�dI��\|��5��Y�w�qG��\]w� '�簾Z<��9�5�ES���c4\|�/�v�65��������u�}���\]��{����foj��l}��ã�9����M�i!� � � � �y�E���q�\\����\[^j�ҥ-�� ����9�Ǭ}��ǻY�nG�:��s\_��j\
� � � � ����H�V=\`�cC�atÞ�zH�g�}��1c�-?����@@@@�j�a�d��O\`��������Q\]=���˞y��0���x���y��3A@@@@ �d��?,���X�"�EA@@@@�z�֛�,@@@@@��I֜
1@@@@@��I֚PLC@@@@r$Ys\*�@@@@@��$YkB1
@@@@� �dͩC@@@@j
�d� �4@@@@@ '@�5�B@@@@�)@��&�@@@@@��I֜

�\]�$�p���G@@��cǎ\
�f�j9�  � 0<x\\����y� � � � � �!���d@@@@�$Y���λF@@@@� �d�$� � � � � ��� �:C�ͪU+�lo6F@�A��'��cp����+��{�"� �����$�ر;l ���V,\[\\{.@Z�ﾭ'1@@�V��t�G��@@@@@�H��§�@@@@@�kH�v�G��@@@@@�H��§�@@@@@�kH�v�G��@@@@@�H��§�@@@@@�kH�v�G��@@@@@�H��§�@@@@@�kH�v�G��@@@@@�H��§�@@@@@�kH�v�G��@@@@@�H��§�@@@@���ܹs��{��7L��W?9΍ � � � �\]!0�+N�?Ć\|��V%��6\[����7����z���� � � �l�\]����$����b�ÝgL���԰瑇����ی�nklٷ�a��a��ᙻ�\

߽�;ſ(�9k֬�$&H���qg������U���e7n�8g�"���x�ڵkG�8��\_'VĄ�\]��\]w�5�~�a��E�V�<��Ês\\w�O¢E���x����xG5jt���\_�ת�/��b�y�M�=g�'��W�\

ӦO\
z.������%��g�\
{��W�L�ԷyTL�^S�AWPw�^s����#o��Uu}%tu���?P�G�����憫��&�+�Ze뉻Wu����?�d���7��� 'ƿ�������1)�h�Cx�k��}7�F���w��\\�l�3�֩�a�K��,��m��U���,Z\_�w8�̋�����y��C�'\_�j�9�u�"4}����/�'c���\_�2�s�Q��Y�:�o��=���rKsM;�����;���h8�����O��~G�f�(c@@@��%0oyL�����;��o��돈��~�7& ֧��O�����ÇO��;\[���^��w\
������W?�<\\���Kg�(�\|�������J����#!W���W<FŽ/?g�p�����.�f^Xϣ�<~�o�9�O�:o�p�v��g�~��/�eqlK%6U�l��Z�P}�����J������U1W�;\_uS���1)��2\*���c�\[Ѿ���荿%��\*'���n���/��B����gkio��z^/���bu~Vѧ�~��U�ܒ��3T����( �d���� �ys�}b������\*��ox:&5�\_�Z�\|��fH���j�����1k<���a�}� �\_?W��\_�2,�w����\_\|��s3^�\_������K6����ӦO+��c���O�j@���˖Ƅq#�V��ņ��b��S1 :DE��>^������߼�Γ'5�Ǽ�=��8<\|�ϊ$����ݿ���w�����W{��H�d�\|{̀��\|=>>@�2��\|��Ù\\hCE�Ī�\\��w���\

a��7b����ѻ�m&XQ\

��=�5��ٻ���#� � � ��v��M�����L�\
a��ҫ� \_���p�c�SƄ�oi����ů��7\*cS��������O���S,��B��u��t�\*��׿Fl�)�����U�b�ί��\\��\* �;R��ң��XJ�����~S�q3��~�RbUIV�6�ڪU�V�����v�8Vl�a \[@ې�.ۢ�xٺA���i�v��nʎU/�"(����-��J��Gy,�R���ɓ'���=3u��}hH�\_Y�M�V\|ɕ��jE�n�s�9���l��Q���p�{��ݮ�\_j}��X���?���{���?���Y�iq\\�����g�Ǿ���$k�s�������\_�5jl�\_L4Y�^�ߢ��O}���C���8���v�2�H���τe�/��\]���ˬ4t���5����J1��~�\[���.�eq��<��q�\_\_v۷/�������\|\| m={���yQ@@@���wv����S+�o��6��P��X\]��E�=���֗���ֆ:mF3ѩ�����q�U�;e�aѪM� ��51ٻ4�;5�krL���I��alޖ������\]v٥�\`�Y����kUIVK�\*o�\|�~�Z��%i��\_������V�\
P�;a5\_Ec\*J�ꋮ��l���H�v�s�Gx䡇�;�<�H����?������I�\_?5&�����y#ɹ��������������^��\[���vǍ�)�'�w^�jn�4�����ȥ�7���?�uW3^u�3.� �eeL���+O唠W�<���ꫮ�\
ec�V�u��}ё����o�=<�w��\*�q������n�������~�{�\

�M�楱���Y��X�ݺ�Z?������bgj���l5�@@@@�\[�UB17��\|�U���ZJi�n?����V�������ۧ�D��}3�ܼ4Vշ1�u k\[��٘�Us�XU;S\_�\_����jl�,Z � � � ���@����(7��\|�U�ƭֵ�\]V�洊i\\��l���sslnZo�IC�N'Z�lN���1k\[��X��������T����ϲ�������ki#� � � � �9�Dc�k����}��vn�\`bzO~}��9��,��b�O\

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ModifyRecords.html

CloudKit Web Services Reference

On This Page

- Path
- Parameters
- Request
- Response
- Discussion
- Related Framework API

## Modifying Records (records/modify)

Apply multiple types of operations—such as creating, updating, replacing, and deleting records— to different records in a single request.

### Path

`POST [path]/database/[version]/[container]/[environment]/[database]/records/modify`

### Parameters

_path_

The URL to the CloudKit web service, which is `https://api.apple-cloudkit.com`.

_version_

The protocol version—currently, 1.

_container_

A unique identifier for the app’s container. The container ID begins with `iCloud.`.

_environment_

The version of the app’s container. Pass `development` to use the environment that is not accessible by apps available on the store. Pass `production` to use the environment that is accessible by development apps and apps available on the store.

_database_

The database to store the data within the container. The possible values are:

`public`

The database that is accessible to all users of the app.

`private`

The database that contains private data that is visible only to the current user.

`shared`

The database that contains records shared with the current user.

### Request

The POST request is a JSON dictionary containing the following keys:

| Key | Description |
| --- | --- |
| `operations` | An array of dictionaries defining the operations to apply to records in the database. The dictionary keys are described in Record Operation Dictionary. See Data Size Limits for maximum number of operations allowed. This key is required. |
| `zoneID` | A dictionary that identifies a record zone in the database, described in Zone ID Dictionary. |

| `desiredKeys` | An array of strings containing record field names that limit the amount of data returned in the enclosing operation dictionaries. Only the fields specified in the array are returned. The default is `null`, which fetches all record fields. |
| `numbersAsStrings` | A Boolean value indicating whether number fields should be represented by strings. The default value is `false`. |

### Record Operation Dictionary

The operation dictionary keys are:

| Key | Description |
| --- | --- |
| `operationType` | The type of operation. Possible values are described in Operation Type Values. This key is required. |
| `record` | A dictionary representing the record to modify, as described in Record Dictionary. This key is required. |

### Operation Type Values

The possible values for the `operationType` key are:

| Value | Description |
| --- | --- |
| `create` | Create a new record. This operation fails if a record with the same record name already exists. |
| `update` | Update an existing record. Only the fields you specify are changed. |
| `forceUpdate` | Update an existing record regardless of conflicts. Creates a record if it doesn’t exist. |
| `replace` | Replace a record with the specified record. The fields whose values you do not specify are set to `null`. |
| `forceReplace` | Replace a record with the specified record regardless of conflicts. Creates a record if it doesn’t exist. |
| `delete` | Delete the specified record. |
| `forceDelete` | Delete the specified record regardless of conflicts. |

### Response

The response is an array of dictionaries describing the results of the operation. The dictionary contains a single key:

| Key | Description |
| --- | --- |
| `records` | An array containing a result dictionary for each operation in the request. If successful, the result dictionary contains the keys described in Record Dictionary. If unsuccessful, the result dictionary contains the keys described in Record Fetch Error Dictionary. |

### Record Fetch Error Dictionary

The error dictionary describing a failed operation with the following keys:

| Key | Description |
| --- | --- |
| `recordName` | The name of the record that the operation failed on. |
| `reason` | A string indicating the reason for the error. |
| `serverErrorCode` | A string containing the code for the error that occurred. For possible values, see Error Codes. |
| `retryAfter` | The suggested time to wait before trying this operation again. If this key is not set, the operation can’t be retried. |
| `uuid` | A unique identifier for this error. |
| `redirectURL` | A redirect URL for the user to securely sign in using their Apple ID. This key is present when `serverErrorCode` is `AUTHENTICATION_REQUIRED`. |

### Discussion

A request to modify records applies multiple types of operations to different types of records in a single request. Changes are saved to the database in a single operation. If the `atomic` key is `true` and one operation fails, the entire request fails. If the `atomic` key is `false`, some of the operations may succeed even when others fail. The operations are applied in the order in which they appear in the `operations` dictionary. One operation per record is allowed in the `operations` dictionary. The contents of an operation dictionary depends on the type of operation.

For example, to modify records in the Gallery app’s public database in the development environment, compose the URL as follows:

`https://apple-cloudkit.com/database/1/iCloud.com.example.gkumar.Gallery/development/public/records/modify`

Then, construct the request depending on the types of operations you want to apply.

### Creating the JSON Dictionary

Create a JSON dictionary representing the changes you want to make to multiple records in a database. For example, if you want to modify records in the default zone, simply include the operations key and insert the appropriate operation dictionary for the type of operation, described below.

1. `{`
2. ` "operations" : [`\
3. ` // Insert Operation dictionaries in this array`\
4. ` ],`
5. `}`

### Creating Records

To create a single record in the specified database, use the `create` operation type.

1. Create an operation dictionary with these key-value pairs:

1. Set the `operationType` key to `create`.

2. Set the `record` key to a record dictionary describing the new record.
2. Create a record dictionary with these key-value pairs:

1. Set the `recordType` key to the record’s type.

2. Set the `recordName` key to the record’s name.

If you don’t provide a record name, CloudKit assigns one for you.

3. Set the `fields` key to a dictionary of key-value pairs used to set the record’s fields, as described in Record Field Dictionary.

The keys are the field names and the values are the initial values for the fields.
3. Add the operation dictionary to the `operations` array.

For example, this operation dictionary creates an `Artist` record with the first name “Mei” and last name “Chen”:

01. `{`
02. ` "operationType" : "create",`
03. ` "record" : {`
04. ` "recordType" : "Artist",`
05. ` "fields" : {`
06. ` "firstName" : {"value" : "Mei"},`
07. ` "lastName" : {"value" : "Chen"}`
08. ` }`
09. ` "recordName" : "Mei Chen"`
10. ` },`
11. `}`

### Updating Records

To update the specified fields of an existing record, use the `update` or `forceUpdate` operation type.

1. Set the `operationType` key to `update` or `forceUpdate`.

If you want the operation to fail when there is a conflict, use `update`; otherwise, use `forceUpdate`. The `forceUpdate` operation updates the record regardless of a conflict.

2. Set the `record` key to a record dictionary describing the new field values.
2. Create a record dictionary with these key-value pairs:

1. If `operationType` is `forceUpdate`, set the `recordType` key to the record’s type.

3. Set the `fields` key to a dictionary of key-value pairs used to set the record’s fields.

The keys are the field names and the values are the new values for the fields.

4. If `operationType` is `update`, set the `recordChangeTag` key to the value of the existing record.
3. Add the operation dictionary to the `operations` array in the JSON dictionary.

For example, this operation dictionary changes the `width` and `height` fields of an existing `Artwork` record:

01. `{`
02. ` "operationType" : "update",`
03. ` "record" : {`
04. ` "fields" : {`
05. ` "width": {"value": 18},`
06. ` "height": {"value": 24}`
07. ` }`
08. ` "recordName" : "101",`
09. ` "recordChangeTag" : "e"`
10. ` },`
11. `}`

### Replacing Records

To replace an entire record, use the `replace` or `forceReplace` operation type.

1. Set the `operationType` key to `replace` or `forceReplace`.

If you want the operation to fail when there is a conflict, use `replace`; otherwise, use `forceReplace`.

2. Set the `record` key to a record dictionary identifying the record to replace and containing the replacement record field values.
2. Create a record dictionary with these key-value pairs:

1. Set the `recordName` key to the name of the record you want to replace.

2. Set the `fields` key to a dictionary of key-value pairs used to set the replacement record’s fields. Fields that you omit from the dictionary are set to `null`.

3. If `operationType` is `replace`, set the `recordChangeTag` key to the value of the existing record.
3. Add the operation dictionary to the `operations` array.

### Deleting Records

To delete a record, use the `delete` or `forceDelete` operation type.

1. Set the `operationType` key to `delete` or `forceDelete`.

If you want the operation to fail when there is a conflict, use `delete`; otherwise, use `forceDelete`.

2. Set the `record` key to a record dictionary identifying the record to delete.
2. Create a record dictionary with a single key-value pair, whose key is `recordName`.

3. Add the operation dictionary to the `operations` array.

### Sharing Records

Shared records must have a short GUID. To create a record that will be shared, add the `createShortGUID` key to the record dictionary in the request when you create the record as in:

01. `{`
02. ` "operations": [{`\
03. ` "operationType": "create",`\
04. ` "record": {`\
05. ` "recordName": "RecordA",`\
06. ` "recordType": "myType",`\
07. ` "createShortGUID": true`\
08. ` }`\
09. ` }],`
10. ` "zoneID": {`
11. ` "zoneName": "myCustomZone"`
12. ` }`
13. `}`

In the response, the `shortGUID` key will be set in the record dictionary.

To share this record, create a record of type `cloudKit.share`. If the original record has no `shortGUID` key, one will be created for you. In the request, specify the public permissions and participants as in:

01. `{`
02. ` "operations": [{`\
03. ` "operationType": "create",`\
04. ` "record": {`\
05. ` "recordType": "cloudKit.share",`\
06. ` "fields": {},`\
07. ` "forRecord": {`\
08. ` "recordName": "RecordA",`\
09. ` "recordChangeTag": "2"`\
10. ` },`\
11. ` "publicPermission": "NONE",`\
12. ` "participants": [{`\
13. ` "type": "USER",`\
14. ` "permission": "READ_WRITE",`\
15. ` "acceptanceStatus": "INVITED",`\
16. ` "userIdentity": {`\
17. ` "lookupInfo": {`\
18. ` "emailAddress": "gkumar@mac.com"`\
19. ` }`\
20. ` }`\
21. ` }]`\
22. ` }`\
23. ` }],`
24. ` "zoneID": {`
25. ` "zoneName": "myCustomZone"`
26. ` }`
27. `}`

In the response, the record will have these keys set that are present only in a share, described in Record Dictionary:

- `shortGUID`

- `share`

- `publicPermission`

- `participants`

- `owner`

- `currentUserParticipant`

### Related Framework API

This request is similar to using the `CKModifyRecordsOperation` class in the CloudKit framework.

Composing Web Service Requests

Fetching Records Using a Query (records/query)

[](http://www.apple.com/legal/terms/site.html) \|
[](http://www.apple.com/privacy/) \|
Updated: 2016-06-13

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Art/1_create_api_token_2x.png)

View in English#)

# The page you’re looking for can’t be found.

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/Art/1_create_server_to_server_key_2x.png)

View in English#)

# The page you’re looking for can’t be found.

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/EnablingiCloudandConfiguringCloudKit/EnablingiCloudandConfiguringCloudKit.html

- CloudKit
- Enabling CloudKit in Your App

Article

# Enabling CloudKit in Your App

Configure your app to store data in iCloud using CloudKit.

## Overview

Once you’ve determined that CloudKit is right for your app, you’re ready to set up your Xcode project to enable CloudKit development.

### Add the iCloud capability to your Xcode project

Adding the iCloud capability to your project sets up the initial project entitlements. Before you proceed, verify that your Apple Developer Program membership is active and has admin permissions.

To add the iCloud capability:

1. In the Xcode Project navigator, select your project and your project target.

2. Click the “Signing and Capabilities” tab and select “Automatically manage signing.”

3. Specify your development team.

4. Make sure that your bundle identifier is one you want to use for your app. (This identifier determines the name of the iCloud container created in a later step.)

5. Click the + Capability button, then search for iCloud in the Add Capability editor and select that capability. An iCloud section appears on your app’s Signing and Capabilities page.

### Create your container

Next, add the CloudKit service to add the appropriate entitlements to your project and tell iCloud to create a container for your app data:

1. Select the CloudKit checkbox. In addition to adding the CloudKit capability to your app, this selection also creates an iCloud container and adds the Push Notifications capability. The name of the container is your app’s bundle identifier prefixed with “iCloud.”

2. Check the box next to the container name.

Multiple apps and users have access to iCloud, but each app’s data and schema, together, are typically in separate containers. Although an app can have multiple containers or share a container, each app has one default container. Once you’ve created a container, you can’t delete or rename it.

### Select or create an iCloud account for development

You need an iCloud account to save records to a container. In your app or the simulator on which you test your app during development, enter the credentials for this iCloud account. If you don’t have an iCloud account, create one for use during development. In macOS, launch System Preferences and click Sign In. Click Create Apple ID under the Apple ID text field and follow the instructions.

Note that your iCloud account is distinct from your Apple Developer account; however, you can use the same email address for both. Doing so gives you access to your iCloud account’s private user data in CloudKit Dashboard, which can be helpful for debugging.

### Enter iCloud credentials before running your app

Enter your iCloud account credentials on a simulator or app-testing device. Entering the iCloud credentials enables reading from—and writing to—users’ own private and shared databases and, potentially, writing to the container’s public database.

To enter your credentials on an iOS or iPadOS device:

1. Launch the Settings app and click “Sign in to your iPhone/iPad.”

2. Enter your Apple ID and password.

3. Click Next. Wait until the system verifies your iCloud account.

4. To enable iCloud Drive, choose iCloud and then click the iCloud Drive switch. If the switch doesn’t appear, iCloud Drive is already enabled.

To enter your credentials for macOS, go to System Preferences.

### View your container in CloudKit Console

CloudKit Console is a web-based tool that lets you manage your app’s iCloud containers. It appears within the Apple Developer web portal, and you can use it to ensure that your container exists.

1. Using a web browser, such as Safari, navigate to the CloudKit Console webpage at

2. If you’re asked to sign in, enter your credentials and click Sign In.

3. On the subsequent page, verify that your container appears in the container list.

For more information on CloudKit Console, see Managing iCloud Containers with CloudKit Database App.

## See Also

### Essentials

Deciding whether CloudKit is right for your app

Explore the various options you have for using iCloud to store and sync your app’s data.

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/Art/intro_2x.png

�PNG


IHDR\]gK pHYs��8+iTXtXML:com.adobe.xmpAdobe Photoshop CC 2015 (Macintosh)2015-11-03T11:47:04-08:002015-11-03T11:48:56-08:002015-11-03T11:48:56-08:00image/png2xmp.iid:6270138d-821e-40a7-8704-299226f10258xmp.did:6270138d-821e-40a7-8704-299226f10258xmp.did:6270138d-821e-40a7-8704-299226f10258createdxmp.iid:6270138d-821e-40a7-8704-299226f102582015-11-03T11:47:04-08:00Adobe Photoshop CC 2015 (Macintosh)1720000/10000720000/100002655351308605a&� cHRMz%������u0�\`:�o�\_�FPLTE�����������������������ȹ����������������������������������������������������������˻����������������������������Ŀ�¿�ý����������������������������������������������������������������������������������Ȼ�û����ɻ����������������������������þ����̻�˻�ӻ�л�������������˿�ɾ�ź�������ڻ�ռ������������������������������ڻ�׾�ʻ����������˺����������������������������������������������������������������ý���������������������������������������B��C��D��F��H��K��L��L��N��P��P��S��U��X��Z��\]��b��e��g��i��l��q��t��u��x��{�ǀ�Ʌ�̌�Β�ї�ӛ�֢�ا�ڬ�ݲ�߸������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������v���tRNS���������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������������S�%eIDATx���y\|\[՝����dɻd\[^��Nb;��6��$aM ��-$a+mg\

��l��p�f�!lV�"<�f��\]�:mD�X�l�:Gq1!��Hfm��<)����Z�Q�8۾��H�9�7\[���ƽ�unЩ��V#Z?z�{�z���dG��jQ��p��,��ƚ��f�%$��S���\

���1)կOa\]!ǹ���wM�����;��\_ډ��T�ⱎj�Q�T�X��!�\*Y�Q;��Zz��rcUm�Ԍ�-���H�pKBq���\_Y\`��b\_������E��,}Q\*���?���)�y��G�f^l��B@y\\͞qn�Z��ڼe!I��ģװ�z�ތ:'ر7ږ��L�f��/

�i��'��������\]^mF��븑���s�\\J#l��wvMm�yσV��y�����b-����Re�\`ߘ�ܛ�0�t�\|��B+����N��

�Z��u?ٵ&��lR�le�=o�\
J�S~��8���dV;Bqt,�\`�&���q&pH�lѮ�X�jGجv{r%��t��6��\
�����ׯ=��j\_V;BqtvY��{���y�$�.nM\\d�o���֑�3o������Y�����������a��C&\[+;y�+Na��\_9�V<)���i�������ǚՅ�a�j�������g�Tͬ�\[��s���w\_.O��B�.��$5B4�ˌ���F�q��E�� ����%�f�A�8f%X\|�Em�y����H�r��<�7��8OQ�0�X1�\

9p�\]�\|؎�!G����g�ۚ�{����,�=Bq�0q�;5��\
\\�R�����������\[c9.�ʩ���\\�����S�2�7)����;�m9�縓oQ\[\\U4�m�BY��mC\`�9\
lW��g9�����WYY�3;\_H�N��u;;gY� �ѣXo)�3q�OQ\]�g�R�\*��,�4�\
�';�K�P݇�)ߙ�\[)���,͝�̳TE�U��\*?w�U�d�����X��\\NN\`�Eڥ�!P��!�qh��Ήғ�#��$Wˋ�\[���!?��\
H�9�'Eqˁ�3\_�J�@uQD\]�\\H-�S����r�9'O��X.���҄�jݿ�z�eWk ���d\_\[�(�:!�����h����m;b��/��B\]��N �~�k�iaMt�٤\
��,P���{��\*G(��@^�\]eVN�tI#B^����E�S�� X\
kW��ra��\[P\]�\
9j��J�Xg�bf�d �8��������!�����gў��j7"W��=�g��\*;ڰ���n�F�D���ֺ/2hWB��dUĪ'%}��jk�lC�/�������� ��5��-���ZJ�ُOA;I��;\[0p�Q?Ϫ+ C9Z{��V�Ą���ȉ��煴���������uد���YypD\\�&�f&�\]AiX�\]םM��&zwke�K=�9?���\`Mz�r1��Z�Pg��k#X.q�O�r��4\`����S�$۞�0B �V����?�Y��p������F�ݢ)1�/ܟ�4��;�������GQ9�՝N�S�����׊Y�h0�l�\\.���n��䚜��u��WM��\]����'�e@q$�@A����/
suޝ����m�L��u��
�����^�Y�o�p��N��PG\|Ř=G2�����%���7^��;z�)�b��u��@0WC�\`\`���B�W#e2Ķ�l��x�

���yT�l�Է-�6(P�<�S\\sJEQa��B����u�A&$U������\]N��\_�a��<
��^�&���#�����"�Sp\*�˴�ء˘�gp�T��@���礽k���U�)��C�Y�٬&N�

�\_9?���է^1��\
�����r�j�\|�Y�s&�z�kf���S��d�J�g���AgG�C��1CY�QH�-�Z�aP�o�5��Cq��8;6㬊#��!�N�$��S��H�p���.���E�5�Ϭk�}#�\

ו9���VU�:�n�3\\� ����u�6fb%̦�{�%�2�/e�r�ϸ@ِ����A�����<��+�TWY��9�(���Mǜ��\]�!'��NA���S����qd�Tf���.v5�����YXG2��Y��8\]U�.����Ȓ.���1-錭Uo���.Y�p����(�Ă4�9;z.�q�˄�� 2��?��2}�\`I�ӷ�#O�����Տ�Qe��R�8�#�H�e����槈\]7~��e" �l� @@06\|\ ���!�ض�1�:b��;oޖQ

(p�Y����F������p���O��Ă�n�Λ\|�d� �.6 x\

v:R�0,R�/�����J���mM��Y�{s����/G��"e��6H�pH\|�C�o6ys�KL����ő��ئw�'L���Y�ɮ\|�\_8���o.��A������8��x̠�=a�O���o�Uiܩ:2�}@z�W����f5őc٣fp�'\|�Jl���vŦ�g�q}�nՅ�'�@����oم�����������'����w@ޜ\|��vU��3�UI�ʆ�κ�g����t}�i+�5^\\���-��ő�.tw�1=mm��
�WG�ޛ�; �\[}��B��;��Nf������\\�\_-\_�.�ς�H�(�ـL\|K��1m���������CG�Fg��v�̧F.��n�<#������m��W7�-���WAq$��81���n��0��4��2W�C��^��l�n�k����2!��m�L��O2�L3�W��-2�X��� �YP�Ԉ���N����k�\

���7Eq$���H1��Sf�ʲ�6/I��i�����\]؂�̾�u���̅

)�8�O�A\
r�E�I�"D�����p@1������$1��\]7Z�bٍ��?�#,wa��K�ٰ�aKYh��Ɩ���߅7���UY4�̲C��V G���i��m� 8ݭ=��YHG"��ȦQf���ȿ�U+�"eK�;^�4��=G9�2�J�3��t�~��=G"&���I�����ӭ�rp�K��#��-�Uh��V�F�����n�-x�� Bq�����6���Ve��!�g�n������Hq$R,���DZř�r�ǲr,�9���v�g�9�,3�#�T�#Gd����?$��^q@�ֲ�C캀�G'��f�Q ˽�4�tqx�.�fyq�&\
@��7���y�X$}���Hq$R�"Xl\*��e��e�/v�K!�۵kt�.B0��A&ʅ��Mï�����z\]��^7���j�V5���H�=Gy�����9\\��ܵ��h�}I3�d~��t�/F������ݿ�Y;^���8'�L�41!�R�a�s�B���d
���S&6u�Ϝ�ebM�X/FE���Ɲ;���1x�@�<���n�n�?
�#���\[4!���X�x,t�ܴ�\\0�,��s\_�����'��vE�8zk��&�.)~\
�@@\_Y�\
��}\\�H��Q(�^�6O\]��BW�v�� ?����Ҽކ��Jh6����kD��%��1���-�۟qL��OL���E�A��ifo"�rV��V���ed-\_�3��k����mu��.uD-��L�D��'�ij/b�\]��s�\`r�ߡX�\|hO/m� ��d��i�#2u1~t�}�h���Ӭ���ނ�n(�V�8z���E�?�X$�Lڶ�=�?�41�/{�$��t�\]��&��K��r�Q(�^��OD�i���Q�
:u,�֧��'�S������~�:Z�+ު~lU{-�s�~���ukq�NU\

.�F�:�~Jm�J7e�)��q��֨C���U��V\

'���n=G�Xi~ϯ�l-�Jb��#��%ZR/(�{��͓��\|V�l\[\[�}��Rl2�c�gh���B� ���Wx���jB�T o���Yj���T�?풇�D\\<'BX�㛪�����;��W#h��5� �z�=�)��d�4��Mڥ�������z:����?�%}m}U�=$w��o\

�e{��m�j���K-'2�\
��C���x�ح����m��''��(�L͝�B�WL� \*B(�5#!�cj���0�\

@�v֣�\*��h��1;��gq8�{Ϗ��ȅC����Y��.6Ǟ(��1k(b�Z�欍���=�����I/�Kߺ���jMl{��'�G�qUԞ\\�(Ÿ���ڈ��-K�u̲�l�����G^�q�=��N��ڐ8�������hW7�79���g$W�G�w�(�SC���V��� �ίb���h�K\

�U�IȲc~3=̏\_t(��.�#td�@TW�6oM(:j��ʻ�ۯ�b�����96Z��P%\_9��x��FU/�F����+7P��Y��Vv5LP:\]��W�45�C^���}k�'�2�d8��?47\
dN��\_=<��ϝe��Z��k�l����7E���ӡ;c�O��+^5^0������U�Ꞧ�j���\
'���K-��Y���ѫ�Q�@s׸���&�tO�YC-�����K�d��鶕i3�S�\[�f�����9ެƏ�ĝ�8��s�z��&&�~��FQ�<�3\
��v���{��Xi�=�\[#��\
��\|�5�vUz��'�ʒ������8��@c������y�e=��)9ڎ�O;\*�^³!/�I~b��+:::n@��~�S�8D��㞣3���<�^���v�\

9���Z?�h$��4w���}m�3�8�2�8r�� �1\\X���)<��SY�\*«ڽg��R�F��J/�j��Ɩ�a�����-�o\
w�^Ln��q�,���\*��0�N �������l\[�'k}�\]jT����j#p⺿A6�:�\|kz��0���jV�9�9�K�d\

����m眙�՚�Z��K��Kk#��P�a�X�呩T�wg�7�/�Ff��\\u�!��q��vU\`����^�\|r�,���S�<�z�/��Zj����'�R���yFZ�ݕS�d}�����!g�������.��6\

�!����D}�\[z����\_�\|��b�Ym�6�!V�\
���:�I:j#�q:���g-\
8w��)\]��ʗ\
ȱ#��v�1�'�(˕I&obmؽO��\|ZM��\

@l��Z�N��e���IUq�w�����7G��v?ʅx���s�O��^�z�M���F���L2i�������Ϣ����J��\\�ӷcj����������B���Zr��&�I�Il�����(y�����bEP����}@���2i#p��W��y����T(�\*�<���p�9c�l8����\|��G�ײG2\]sВī���&�^��4�S~ugv�pY�����1�ˈ�o-��&O���8J��nm�����ϊ���EG'\[�xfu�,���G��<��W�B�\
�ƭG�6��u)�V���r�\*�)dɶ� �A{?%�Yo\|\_��L��}V�\
��4��w#� \|ͱ�nٓ\\�7��?�����Iɢ8N�\
���c�kځl:~�VQ�d;�cAWϛG�JT�L5� ?�mx�3K��eA�\\aJ�ꇶ��5mT5�'��.�\*������I�p��\_��\*��T���Ƴ�@�Ev{��㚺E��$ph��3�c��������4"���oe��@İ�V�$���d�#��1�l���(��0�妶���n($�m�o�~�e����1�q�<�yI��\`�m��eّH��ah��~�M/�h�����H�7Z/v�A�ʩ�x\[�s���N�)\
�Ȋ�\]4J�����q��~�����M�8�Y=eV�D�9:��ϡLR�7�\]�u�Z��q���io����"\_V�����/�4��)�Zl^j0��k�{���GwI�W�#�\]�P=�omh����G@���iX�R�8:��x5���#�ߝ�ݲt��L�5���ɻ��#+�X�\

�����\`o�ٗ�e:�d�S�y�Fu�L꘴ �Oh���ͿcQg�\
���V�D�upwb7 ��ʷ����;�t�ڼTnڻ\

��8��h��zn-C�qn��S�R{���p \[:������d�9���������v�k�{\

,�~��?�\|\_�0,�@3���H���\\�M���a�S���q����~D\[�YM�'��1�$�$��ΰ��Lm�\

6�8${��dZ��s4sJ������\`�^��o��0�5�śKi\*Bq4�o\`��n0���m�b�^\]���W����B�"�O�B�z'�a���{&���ꯖ���\\�c��sL��#���nz#����lS�È����aJI���׈����\\��w��� ��x�%�#���F����t�Ѹ^�\

�N0�f�p�F��Y\
d��u�i"!����j�mD��nӱXD�o�,���B��=�'ԙ\_�уV�\\,7��Ni�YA��G�\

m�����Cw�p��H��&sW��l^ٹ�t8���#^լ&Ă�ۍ�E��ꄋ���H����G�\|l^l~�F��p��H��B����+\
��sY�őx{m�7\
6���d:\\�����H�1�tb��(���H��x��uخ9��6h8Bq$�̀�t8�m�J�&ӡ<��#G����m�F��Xl:�LBq$^�!�������8�N��p��H�������򳦰���H�P�w��x��x���ۺL�k���#G�ݤk"L�C\_Yw��I �x$\\\[M�@w�9Ʒ��\`%F��i����E�z���yC4�{���U����W\
�4�8o'm�:�����qh������F(���Y�Xn:���X���@���ܼ��:�\
4�8���y����Y��M��Nky��ߪ�G�1q邧i4Bq$s��� &m����:�c�j:������1��MF<��Ve4���˄UgG�0�mU����v �KYS\\\|�\`���{�p�\[;MF(�S��B�c��%��j#��H��%^�P���<2rѰ:&-�ߗA����,T8�I�c,1W���zI�j�6����ow�=o\\Y��2�P�\
��t^�o�Xm�f����7�R���2U�jVL�1�/���V��st/UDꌋN��rqkZ��4ɠZ�&�'h\*B��IS����X=��������E�l�t�ߝKC��s�ݿ�u��ށKw�\`ܼe��!\|�u�1m�������ITv�׳\`ܜ\_}�Z��bZ{s\\�K��H(��␲�<\`P\_��qw2�\

��H$�&58I��#q\[�ڃ�J�0(���\
S/\`SI�عP\[:��v�\`04;䙎�c�H$���� ��r$�G�8�\\�I�N�$�#�E�����iݫ#\
����$���\[\|���"-J���/Y~��#qqt��8�O�f5!�P !��H!GB�8BőB(��Bq$�Bq$��#!�P !��H!GB�8BőB(��Bq$��#!�P !��H!GB�82�d���H<#�6\[���8�8�@�ֽ䀞'G����ֽAZ�P�GpPT�έ��a�� őx�z�g�V�@-N(��3螵N����&G�!t�¬��}�ڛP���5Y�l�(D@\_;�M(��C�l�f�TM47�8��u�Y�����IkOÇ&�����;�wi�\[imBϑx���zf�Q�6P őx!\[\\5�M���҄�H<��\\#���\`�JM���ZAK�Ch��\]e0��T�c�Z���qi���/\

�{&���:V١�!@{+��\`�#�^% ����vld�L!�K�oT\
�z��E3Bd0XJq$.�}��B#�t;%��ѝ��N�����!(&�+����j�R2��=���c\_cx�"+�j--��Y��1�a����W�S��N\_i�%�gؾ&wEx��2���6�#!��YM!GB�8BőB(��Bq$�Bq$��#!�P !��H!GB�8BőB(��Bq$����L�l;�IEND�B\`�

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/Glossary/Glossary.html

Documentation Archive Developer

Search

Search Documentation Archive

Previous

# Glossary

- **ad hoc provisioning profile**
A type of distribution provisioning profile used for distributing iOS, tvOS, and watchOS apps for testing.

- **Apple Developer Program**
Subscription services that offer Apple developers access to technical resources and support to develop iOS, watchOS, tvOS, and Mac apps for the store.

- **Apple Push Notification service (APNs)**
Apple service for propagating information to apps running on different platform devices.

- **Apple ID**
An Apple-issued developer account with a name and password. Developers use their Apple ID credentials to sign in to any of the Apple Developer Program tools. A developer or Apple ID can belong to multiple teams.

- **CloudKit**
An app service that stores structured application and user data in iCloud.

- **container**
A data store containing multiple database used by one or more apps. The default container ID matches the app’s bundle ID.

- **container ID**
A unique identifier for an app’s iCloud container.

- **database**
The portion of a container used to store records. There’s one public database for the app and multiple private databases—one private database for each user.

- **development environment**
Databases used to develop your app and evolve the schema that is not accessible by apps sold on the store.

- **field**
A property of a record type that can be set using a key-value pair.

- **iOS App file**
A type of OS X file that can be installed on iOS and tvOS devices.

- **just-in-time schema**
Development environment feature that allows an app to create a schema by saving records.

- **predicate**
An object that defines logical conditions for searching for objects conforming to key-value coding.

- **private database**
A database for storing records owned by the current user that are not readable by the app unless the user enters their iCloud credentials on the device.

- **production environment**
Databases accessed by apps sold on the store.

- **public database**
A database for storing records owned by the app that are shared between users. An iCloud account is not required to read records but is required to write records.

- **push notifications**
A notification from a provider to a device transported by APNs.

- **record**
An instance of a record type that can be created, read, and written to a database.

- **record identifier**
An identifier for the location of a record in a database. Contains a record name and zone.

- **record name**
A unique identifier for a record within a given zone. The record name is supplied by the app and can be used as a foreign key in another data source.

- **record type**
A template for a set of records that have common fields.

- **record zone**
A partition of a database to store records. Each database has a default zone and allows additional custom zones.

- **relationship**
A record type field that associates one record to another.

- **schema**
A collection of metadata that describes the organization of records, fields, and relationships in a database. In CloudKit, the schema includes record types, security roles, and subscription types.

- **security role**
Permissions for a group of users to create, read, and write records in the public database. The possible roles are world, authenticated, and creator.

- **store**
Used as a short form of the App Store, Apple TV App Store, or the Mac App Store when there’s no distinction between them.

- **subscription**
A persistent query on the server that triggers notifications when records change.

- **to-many relationship**
An association between a single record and one or more other records.

- **to-one relationship**
An association between a single record and another single record.

- **tvOS**
The operating system the runs on an Apple TV device.

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2017-09-19

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/DesigningforCloudKit/DesigningforCloudKit.html

Documentation Archive Developer

Search

Search Documentation Archive

Next Previous

# Designing for CloudKit

CloudKit provides a way to store data as records in a database that users of your app can share. Record types are used to differentiate between records storing different types of information. Each record is a dictionary of key-value pairs, with each key representing one field of the record. Fields can contain simple types (such as strings, numbers, and dates) or more complex types (such as locations, references, and assets).

You can represent all the persistent model objects in your app using a CloudKit schema. However, the CloudKit framework should not be used to replace model objects in your app and should not be used for storing objects locally. It is a service for moving data to and from iCloud and sharing data between users of your app. It’s your responsibility to convert model objects to records that you save using CloudKit, and to fetch changes made by other users and apply those changes to your model objects.

With CloudKit, you decide when to move data from your app to iCloud and from iCloud to your app. Although CloudKit provides facilities to keep you informed when changes occur, you must still fetch those changes explicitly. Because you decide when to fetch and save data, you are responsible for ensuring that data is fetched at the right times and in the right order, and you are responsible for handling any errors that arise.

Once you have a native CloudKit app, you can provide a web app that accesses the same containers as your native CloudKit app. To get started creating a native CloudKit app and using the developer tools, read _CloudKit Quick Start_. To create a web app, see _CloudKit JS Reference_ or _CloudKit Web Services Reference_.

## Enabling CloudKit

Before you can use CloudKit, you must enable your app’s target in the Xcode project to use iCloud and CloudKit. Using Xcode to configure CloudKit adds the necessary entitlements to your app and configures your app to use a default container based on its bundle ID. You can create additional containers and also share them between your apps. As soon as Xcode creates the containers for you, you can access them using the CloudKit Dashboard web tool. To enable CloudKit in your Xcode project and to use CloudKit Dashboard, read Enabling CloudKit in Your App.

## Containers and Databases

Like other iCloud technologies, CloudKit organizes data using containers. A container represents your app’s iCloud storage. At runtime, you can perform tasks against a specific container using a `CKContainer` object.

Each container is divided into public and private databases, each of which is represented by a `CKDatabase` object. Any data written to the private database is visible only to the current user and is stored in that user’s iCloud account. Data written to the public database is visible to all users of the app and is stored in the app’s iCloud storage.

For a running CloudKit app, a container’s public database is always readable, even when the user is not signed in to their iCloud account on the device. Saving records to the public database and accessing the private database requires that the user be signed in. If your app does more than read data from the public database, check to see whether the user is signed in before saving records. To avoid errors, disable the parts of your user interface that save records until the user signs in.

To check the iCloud credentials for a CloudKit app, read Alert the User to Enter iCloud Credentials.

## Managing Data in CloudKit

Inside the public and private databases, you organize your app’s data using records, represented by instances of the `CKRecord` class. You fetch and save records using either operation objects or convenience methods in the `CKContainer` and `CKDatabase` classes. Operation objects can operate on multiple records at once and can be configured with dependencies to ensure that records are saved in the proper order. Operation objects are based on the `NSOperation` class and can be integrated with your app’s other workflows.

If you know the ID of the record you want, use a fetch operation. If you do not know the ID of a record, CloudKit provides the ability to query for records using a predicate. A predicate-based query lets you locate records whose fields contain certain values. You use this predicate with a `CKQuery` object to specify both the search criteria and sorting options for the returned records. You then execute the query using a `CKQueryOperation` object.

Alternatively, use subscriptions to let the server notify you when certain parts of the database change. Subscriptions act like a persistent query on the server. You configure a `CKSubscription` object much as you do a `CKQuery` object, but instead of executing that query explicitly, you save the subscription to the server. After that, the server sends push notifications to your app whenever a change occurs that matches the predicate. For example, you can use subscriptions to detect the creation or deletion of records or to detect when the field of a record changes to a specific value. Upon receiving the push notification from the server, you can fetch the changed record and update your object model.

To save and fetch records, read Creating a Database Schema by Saving Records and Fetching Records. To subscribe to record changes, read Subscribing to Record Changes.

## The Development and Production Environments

CloudKit provides separate development and production environments for storing your container’s schema and records. The development environment is a more flexible environment that is available to members of your development team. In the development environment, your app can save records. Or you can add fields to records that aren’t in the schema and then CloudKit creates the corresponding record types and fields for you. This feature is not available in the production environment.

When you are ready to distribute your app for testing, you migrate the development schema to the production environment using CloudKit Dashboard. (CloudKit Dashboard does not copy the records from the development to the production environment.) After you deploy the schema to the production environment, you can still modify the schema in the development environment but can’t delete record types and fields that were previously deployed. When exporting your app from Xcode to distribute it for testing, you can choose whether to target the CloudKit development or production environment.

When you are ready to upload your app to iTunes Connect to distribute your app using TestFlight or the store, Xcode automatically configures your app to use the production environment. An app uploaded to iTunes Connect can be configured to use only the production environment.

To perform these tasks, read Testing Your CloudKit App and Deploying the Schema.

## The Basic CloudKit Workflow

Most CloudKit operations are performed asynchronously and require that you provide a completion handler to process the results. All operations rely on the user being connected to the network, so you should be prepared to handle errors that may occur. Your app should also be mindful of the number of requests it makes and size of the data that is transmitted back and forth to iCloud. Here’s the basic workflow of a typical CloudKit app:

1. Fetch records needed to launch your app and initially present data to the user.

2. Perform queries based on the user’s actions or preferences.

3. Save changes to either the private or public database.

4. Batch multiple save and fetch operations in a single operation.

5. Create subscriptions to receive push notifications when records of interest change.

6. Update the object model and views when the app receives changes to records.

7. Handle errors that may occur when executing asynchronous operations.

CloudKit saves each record atomically. If you need to save a group of records in a single atomic transaction, save them to a custom zone, which you can create using the `CKRecordZone` class. Zones are a useful way to arrange a discrete group of records, but they are supported only in private databases. Zones cannot be created in a public database.

To batch operations, read Batch Operations to Save and Fetch Multiple Records.

## Tips for Designing Your Schema

When defining your app’s record types, it helps to understand how you use those record types in your app. Here are some tips to help you make better choices during the design process:

- **Organize your records around a central record type.** A good organization strategy is to define one primary record type and additional record types to support the primary type. Using this type of organization lets you focus your queries on your primary record type and then fetch any supporting objects as needed. For example, a calendar app might define a single calendar record (the primary record type), as well as multiple event records (a secondary record type) corresponding to events on that calendar.

- **Use references to represent relationships between your model objects.** Use a `CKReference` object to represent a formal one-to-one or one-to-many relationship between model objects. References also let you establish an ownership model between records that can make deleting records easier.

- **Include version information in your records.** A version number can help you decide at runtime what information might be available in a given record.

- **Handle missing keys gracefully in your code.** For each record you create, you are not required to provide values for all keys contained in the record type. For any keys you do not specify, CloudKit sets the corresponding value to `nil`. Your app should be able to handle keys with `nil` values in an appropriate way. Being able to handle these “missing keys” becomes important when new versions of your app access records created by an older version.

- **Avoid complex graphs of records.** Creating a complex network of references between records may result in problems later when you need to update or delete records. If the owner references among your records are complex, it might be difficult to delete records later without leaving other records in an inconsistent state.

- **Use assets for discrete data files.** When you want to associate images or other discrete files with a record, use an Asset type (a `CKAsset` object in your code) to represent that field in the record. The total size of a record’s data is limited to 1 MB, though assets do not count against that limit.

To add references to your record types, read Adding Reference Fields. To store large files or location data, read Using Asset and Location Fields. For data size limits, see “Data Size Limits” in _CloudKit Web Services Reference_.

## Tips for Migrating Records to a New Schema

As you design the record types for your app, make sure those records meet your needs but do not restrict you from making changes to the schema in the future. After you deploy the schema to the production environment, you can add fields to a record, but you cannot delete a field or change its data type. Follow these tips to make updating your schema easier in the future:

- **Add new fields to represent new data types.** A new version of your app can add the missing keys to records as it fetches and saves them to the database.

- **Define record types that do not lose data integrity easily.** Each new version of your app must create records that do not break older versions of the app. The best way to ensure data integrity is to minimize the amount of validation required for a record:

- Avoid fields that have a narrow range of acceptable values, the changing of which might cause older versions of the app to treat the data as invalid.

- Avoid fields whose values are dependent on the values of other fields. Creating dependent fields means you have to write validation logic to ensure the values of those fields are correct. Once created, this kind of validation logic is difficult to change later without breaking older versions of your app.

- Minimize the number of required fields for a given record. As soon as you require the presence of a field, every version of your app after that must populate that field with data. Treating fields as optional gives you more flexibility to modify your schema later.
- **Handle missing keys gracefully.** If a record is missing a key, add it in the background.

To modify your schema using CloudKit Dashboard, read Using CloudKit Dashboard to Manage Databases.

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2015-12-17

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/EnablingiCloudandConfiguringCloudKit/EnablingiCloudandConfiguringCloudKit.html)

- CloudKit
- Enabling CloudKit in Your App

Article

# Enabling CloudKit in Your App

Configure your app to store data in iCloud using CloudKit.

## Overview

Once you’ve determined that CloudKit is right for your app, you’re ready to set up your Xcode project to enable CloudKit development.

### Add the iCloud capability to your Xcode project

Adding the iCloud capability to your project sets up the initial project entitlements. Before you proceed, verify that your Apple Developer Program membership is active and has admin permissions.

To add the iCloud capability:

1. In the Xcode Project navigator, select your project and your project target.

2. Click the “Signing and Capabilities” tab and select “Automatically manage signing.”

3. Specify your development team.

4. Make sure that your bundle identifier is one you want to use for your app. (This identifier determines the name of the iCloud container created in a later step.)

5. Click the + Capability button, then search for iCloud in the Add Capability editor and select that capability. An iCloud section appears on your app’s Signing and Capabilities page.

### Create your container

Next, add the CloudKit service to add the appropriate entitlements to your project and tell iCloud to create a container for your app data:

1. Select the CloudKit checkbox. In addition to adding the CloudKit capability to your app, this selection also creates an iCloud container and adds the Push Notifications capability. The name of the container is your app’s bundle identifier prefixed with “iCloud.”

2. Check the box next to the container name.

Multiple apps and users have access to iCloud, but each app’s data and schema, together, are typically in separate containers. Although an app can have multiple containers or share a container, each app has one default container. Once you’ve created a container, you can’t delete or rename it.

### Select or create an iCloud account for development

You need an iCloud account to save records to a container. In your app or the simulator on which you test your app during development, enter the credentials for this iCloud account. If you don’t have an iCloud account, create one for use during development. In macOS, launch System Preferences and click Sign In. Click Create Apple ID under the Apple ID text field and follow the instructions.

Note that your iCloud account is distinct from your Apple Developer account; however, you can use the same email address for both. Doing so gives you access to your iCloud account’s private user data in CloudKit Dashboard, which can be helpful for debugging.

### Enter iCloud credentials before running your app

Enter your iCloud account credentials on a simulator or app-testing device. Entering the iCloud credentials enables reading from—and writing to—users’ own private and shared databases and, potentially, writing to the container’s public database.

To enter your credentials on an iOS or iPadOS device:

1. Launch the Settings app and click “Sign in to your iPhone/iPad.”

2. Enter your Apple ID and password.

3. Click Next. Wait until the system verifies your iCloud account.

4. To enable iCloud Drive, choose iCloud and then click the iCloud Drive switch. If the switch doesn’t appear, iCloud Drive is already enabled.

To enter your credentials for macOS, go to System Preferences.

### View your container in CloudKit Console

CloudKit Console is a web-based tool that lets you manage your app’s iCloud containers. It appears within the Apple Developer web portal, and you can use it to ensure that your container exists.

1. Using a web browser, such as Safari, navigate to the CloudKit Console webpage at

2. If you’re asked to sign in, enter your credentials and click Sign In.

3. On the subsequent page, verify that your container appears in the container list.

For more information on CloudKit Console, see Managing iCloud Containers with CloudKit Database App.

## See Also

### Essentials

Deciding whether CloudKit is right for your app

Explore the various options you have for using iCloud to store and sync your app’s data.

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitQuickStart/Art/intro_2x.png)

View in English#)

# The page you’re looking for can’t be found.

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html

Documentation Archive Developer

Search

Search Documentation Archive

Next Previous

# iCloud Fundamentals (Key-Value and Document Storage)

From the perspective of users, iCloud is a simple feature that automatically makes their personal content available on all their devices. To allow your app to participate in this “magic,” you design and implement your app somewhat differently than you would otherwise; in particular, you need to learn about your app’s roles when it participates with iCloud.

These roles, and the specifics of your iCloud adoption process, depend on your app. You design how your app manages its data, so only you can decide which iCloud supporting technologies your app needs and which ones it does not.

This chapter gets you started with the fundamental elements of iCloud key-value and document storage that all developers need to know.

## First, Provision Your Development Devices

To start developing an iCloud app, you must create an App ID and provisioning profile, described in _App Distribution Quick Start_. Then enable the iCloud service you want to use, described in Adding iCloud Support in _App Distribution Guide_. For a list of the app services that are available for your platform and type of developer program membership, see Supported Capabilities.

## iCloud Data Transfer Proceeds Automatically and Securely

For most iCloud services, your app does not communicate directly with iCloud servers. Instead, the operating system initiates and manages uploading and downloading of data for the devices attached to an iCloud account. For all iCloud services, the high-level process for using those services is as follows:

1. Configure the access to your app’s _iCloud containers_. Configuration involves requesting entitlements and programmatically initializing those containers before using them.

2. Design your app to respond appropriately to changes in the availability of iCloud (such as if a user signs out of iCloud) and to changes in the locations of files (because instances of your app on other devices can rename, move, duplicate, or delete files).

3. Read and write using the APIs of the technology you are using.

4. The operating system coordinates the transfer of data to and from iCloud as needed.

The iCloud services encrypt data prior to transit and iCloud servers continue to store the data in an encrypted format, using secure tokens for authentication. For more information about data security and privacy concerns related to iCloud, see iCloud security and privacy overview.

## The iCloud Container, iCloud Storage, and Entitlements

To save data to iCloud, your app places data in special file system locations known as iCloud containers. An _iCloud container_ (also referred to as a _ubiquity container_) serves as the local representation of the corresponding iCloud storage. It is separate from the rest of your app’s data, as shown in Figure 1-1.

**Figure 1-1**  Your app’s main iCloud (ubiquity) container in context![](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Art/iCloud_architecture_2x.png)

To enable access to any iCloud containers, you request the appropriate entitlements.

### Request Access to iCloud Using Xcode Capabilities

The Capabilities tab of your Xcode project manages the creation of the entitlements and containers your app needs to access iCloud. After enabling the iCloud capability, Xcode creates an entitlements file (if one does not already exist) and configures it with the entitlements for the services you selected. As needed, Xcode can also handle any additional configuration, such as the creation of your app’s associated containers.

When you enable iCloud Documents, Xcode configures your app to access the iCloud container whose name is based on the app’s bundle ID. Most apps should only need access to the default container. If your apps share data among each other, configure your targets to share containers, described in Specifying Custom Containers. When an app has access to multiple container IDs, the first ID in the access list is special because it is the app’s primary iCloud container. In OS X, it is also the container whose contents are displayed in the `NSDocument` open and save dialogs.

For information about how to choose the correct iCloud technology for your app, see Choose the Proper iCloud Storage API.

### Configuring a Common iCloud Container for Multiple Apps

In the Xcode target editor’s Summary pane, you can request access to as many iCloud containers as you need for your app. This feature is useful if you want multiple apps to share documents. For example, if you provide a free and paid version of your app, you might want users to retain access to their iCloud documents when they upgrade from the free version to the paid version. In such a scenario, configure both apps to write their data to the same iCloud container.

To configure a common iCloud container

1. Designate one of your iCloud-enabled apps as the primary app. That app’s iCloud container becomes the common container.

For example, in the case of a free and paid app, you might designate the paid app as the primary app.

2. Enable the iCloud capability for each app.

3. Configure the primary app with only the default container identifier.

4. For each secondary app, enable the “Specify custom container identifiers” option and add the container identifier of the primary app to the list of containers.

When reading and writing files in both your primary and secondary apps, build URLs and search for files only in the common storage container. To retrieve the URL for the common storage container, pass the container identifier of your primary app to the `URLForUbiquityContainerIdentifier:` method of `NSFileManager`. Do not pass `nil` to that method because doing so returns the app’s default container, which is different for each app. Explicitly specifying the container identifier always yields the correct container directory.

For more information about how to configure app capabilities, see Adding Capabilities in _App Distribution Guide_.

### Configuring Common Key-Value Storage for Multiple Apps

If you provide a free and paid version of your app, and want to use the same key-value storage for both, you can do that.

To configure common key-value storage for multiple apps

1. Designate one of your iCloud-enabled apps as the primary app.

That app’s iCloud container becomes the common container. For example, in the case of a free and paid app, you might designate the paid app as the primary app.

3. Enable the key-value storage option for both apps.

Xcode automatically adds entitlements to each app and assigns an iCloud container based on the app’s bundle ID.

4. For all but the primary app, change the iCloud container ID manually in the app’s `.entitlements` file.

Set the value of the `com.apple.developer.ubiquity-kvstore-identifier` key to the ID of your primary app.

## iCloud Containers Have Minimal Structure

The structure of a newly created iCloud container is minimal—having only a `Documents` subdirectory. For document storage, you can arrange files inside the container in whatever way you choose. This allows you to define the structure as needed for your app, such as by adding custom directories and custom files at the top level of the container, as indicated in Figure 1-2.

**Figure 1-2**  The structure of an iCloud container directory![](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Art/icloud_directories_2x.png)

You can write files and create subdirectories within the `Documents` subdirectory. You can create files or additional subdirectories in any directory you create. Perform all such operations using an `NSFileManager` object using file coordination. See The Role of File Coordinators and Presenters in _File System Programming Guide_.

The `Documents` subdirectory is the public face of an iCloud container. When a user examines the iCloud storage for your app (using Settings in iOS or System Preferences in OS X), files or file packages in the `Documents` subdirectory are listed and can be deleted individually. Files outside of the `Documents` subdirectory are treated as private to your app. If users want to delete anything outside of the `Documents` subdirectories of your iCloud containers, they must delete _everything_ outside of those subdirectories.

To see the user’s view of iCloud storage, do the following, first ensuring that you have at least one iCloud-enabled app installed:

- In OS X, open System Preferences. Then open the iCloud preferences pane and click Manage.

## A User’s iCloud Storage Is Limited

Each iCloud user receives an allotment of complimentary storage space and can purchase more as needed. Because this space is shared by a user’s iCloud-enabled iOS and Mac apps, a user with many apps can run out of space. For this reason, to be a good iCloud citizen, it’s important that your app saves to iCloud only what is needed in iCloud. Specifically:

- **DO** store the following in iCloud:

- User documents

- App-specific files containing user-created data

- Preferences and app state (using key-value storage, which does not count against a user’s iCloud storage allotment)

- Change log files for a SQLite database (a SQLite database’s store file must never be stored in iCloud)
- **DO NOT** store the following in iCloud:

- Cache files

- Temporary files

- App support files that your app creates and can recreate

- Large downloaded data files

There may be times when a user wants to delete content from iCloud. Provide UI to help your users understand that deleting a document from iCloud removes it from the user’s iCloud account _and_ from all of their iCloud-enabled devices. Provide users with the opportunity to confirm or cancel deletion.

One way to prevent files and directories from being stored in iCloud is to add the `.nosync` extension to the file or directory name. When iCloud encounters files and directories with that extension in the local container directory, it does not transfer them to the server. You might use this extension on temporary files that you want to store inside a file package, but that you do not want transferred with the rest of that package’s contents. Although items with the `.nosync` extension are not transferred to the server, they are still bound to their parent directory. When you delete the parent directory in iCloud, or when you evict the parent directory and its contents locally, the entire contents of that directory are deleted, including any `.nosync` items.

### The System Manages Local iCloud Storage

iCloud data lives on Apple’s iCloud servers, but the system maintains a local cache of data on each of the user’s devices, as shown in Figure 1-3. Local caching of iCloud data allows users to continue working even when the network is unavailable, such as when they turn on airplane mode.

**Figure 1-3**  iCloud files are cached on local devices and stored in iCloud![](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Art/syncing_overview_2x.png)

Because the local cache of iCloud data shares space with the other files on a device, in some cases there is not sufficient local storage available for all of a user’s iCloud data. The system addresses this issue by maintaining an optimized subset of files and other data objects locally. At the same time, the system keeps all file-related metadata local, thereby ensuring that your app’s users can access all their files, local or not. For example, the system might evict a file from its iCloud container if that file is not being used and local space is needed for another file that the user wants now; but updated metadata for the evicted file remains local. The user can still see the name and other information for the evicted file, and, if connected to the network, can open it.

### Your App Can Help Manage Local Storage in Some Cases

Document-based apps usually do not need to manage the local availability of iCloud files and should let the system handle eviction of files. There are two exceptions:

- If a user file is not currently needed and unlikely to be needed soon, you can help the system by explicitly evicting that file from the iCloud container by calling the `NSFileManager` method `evictUbiquitousItemAtURL:error:`.

- Conversely, if you explicitly want to ensure that a file is available locally, you can initiate a download to an iCloud container by calling the `NSFileManager` method `startDownloadingUbiquitousItemAtURL:error:`. For more information about this process, see App Responsibilities for Using iCloud Documents.

## Prepare Your App to Use iCloud

When users launch your iCloud-enabled app for the first time, invite them to use iCloud. The choice should be all-or-none. In particular, it is best practice to:

- Use iCloud exclusively or use local storage exclusively; in other words, do not attempt to mirror documents between your iCloud container and your app’s local data container.

- Don’t prompt users again about whether they want to use iCloud vs. local storage, unless they delete and reinstall your app.

Early in your app launch process—in the `application:didFinishLaunchingWithOptions:` method (iOS) or `applicationDidFinishLaunching:` method (OS X)—check for iCloud availability by getting the value of the `ubiquityIdentityToken` property of `NSFileManager`, as shown in Listing 1-1.

**Listing 1-1**  Obtaining the iCloud token

| |
| --- |

Access this property from your app’s main thread. The value of the property is a unique token representing the currently active iCloud account. You can compare tokens to detect if the current account is different from the previously used one, as explained in Handle Changes in iCloud Availability. To enable comparisons, archive the newly acquired token in the user defaults database, using code like that shown in Listing 1-2. This code takes advantage of the fact that the `ubiquityIdentityToken` property conforms to the `NSCoding` protocol.

**Listing 1-2**  Archiving iCloud availability in the user defaults database

If the user enables airplane mode on a device, iCloud itself becomes inaccessible but the current iCloud account remains signed in. Even in airplane mode, the `ubiquityIdentityToken` property contains the token for the current iCloud account.

If a user signs out of iCloud, such as by turning off Documents & Data in Settings, the value of the `ubiquityIdentityToken` property changes to `nil`. To detect when a user signs in or out of iCloud, register as an observer of the `NSUbiquityIdentityDidChangeNotification` notification, using code such as that shown in Listing 1-3. Execute this code at launch time or at any point before actively using iCloud.

**Listing 1-3**  Registering for iCloud availability change notifications

After obtaining and archiving the iCloud token and registering for the iCloud notification, your app is ready to invite the user to use iCloud. If this is the user’s first launch of your app with an iCloud account available, display an alert by using code like that shown in Listing 1-4. Save the user’s choice to the user defaults database and use that value to initialize the `firstLaunchWithiCloudAvailable` variable during subsequent launches. This code in the listing is simplified to focus on the sort of language you would display. In an app you intend to provide to customers, you would internationalize this code by using the `NSLocalizedString` (or similar) macro, rather than using strings directly.

**Listing 1-4**  Inviting the user to use iCloud

Although the `ubiquityIdentityToken` property lets you know if a user is signed in to an iCloud account, it does not prepare iCloud for use by your app. In iOS, apps that use document storage must call the `URLForUbiquityContainerIdentifier:` method of the `NSFileManager` method for each supported iCloud container. Always call the `URLForUbiquityContainerIdentifier:` method from a background thread—not from your app’s main thread. This method depends on local and remote services and, for this reason, does not always return immediately. Listing 1-5 shows an example of how to initialize your app’s default container on a background thread.

**Listing 1-5**  Obtaining the URL to your iCloud container

This example assumes that you have previously defined `myContainer` as an instance variable of type `NSURL` prior to executing this code.

## Handle Changes in iCloud Availability

There are times when iCloud may not be available to your app, such as when the user disables the Documents & Data feature or signs out of iCloud. If the current iCloud account becomes unavailable while your app is running or in the background, your app must remove references to user-specific iCloud files and data and to reset or refresh user interface elements that show that data, as depicted in Figure 1-4.

**Figure 1-4**  Timeline for responding to changes in iCloud availability![](https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Art/changed_iCloud_availability_2x.png)

To handle changes in iCloud availability, register to receive the `NSUbiquityIdentityDidChangeNotification` notification. The handler method you register must do the following:

1. Retrieve the new value from the `ubiquityIdentityToken` property.

2. Compare the new value to the previous value, to find out if the user signed out of the account or signed in to a different account.

3. If the values are different, the previously used account is now unavailable. Discard any changes, empty your iCloud-related data caches, and refresh all iCloud-related user interface elements.

If you want to allow users to continue creating content with iCloud unavailable, store that content in your app’s local data container. When the account is again available, move the new content to iCloud. It’s usually best to do this without notifying the user or requiring any interaction from the user.

## Choose the Proper iCloud Storage API

Apple provides the following iCloud storage APIs, each with a different purpose:

- **Key-value storage** is for discrete values such as preferences, settings, and simple app state.

Use iCloud key-value storage for small amounts of data: stocks or weather information, locations, bookmarks, a recent documents list, settings and preferences, and simple game state. Every app submitted to the App Store or Mac App Store should take advantage of key-value storage.

- **iCloud document storage** is for user-visible file-based content, Core Data storage, or for other complex file-based content.

Use iCloud document storage for apps that work with file-based content, such as word-processing documents, diagrams or drawings, or games that need to keep track of complex game state.

- **CloudKit storage** is for storing data as individual records in a private or public database accessible by all your app’s users.

Use CloudKit in situations where key-value storage and document storage are insufficient for your needs. To learn more about CloudKit, read Designing for CloudKit.

Many apps benefit from using key-value storage with other types of storage. For example, say you develop a task management app that lets users apply keywords for organizing their tasks. You could employ iCloud document storage to store the task information and use key-value storage to save the user-entered keywords.

If your app uses Core Data, either for documents or for a shoebox-style app like iPhoto, use iCloud document storage. To learn how to adopt iCloud in your Core Data app, see Designing for Core Data in iCloud.

If your app needs to store passwords, do not use iCloud storage APIs for that. The correct API for storing and managing passwords is Keychain Services, as described in _Keychain Services Reference_.

Use Table 1-1 to help you pick the iCloud storage scheme that is right for each of your app’s needs.

| Element | iCloud document storage | Key-value storage | CloudKit |
| --- | --- | --- | --- |
| Purpose | User documents, complex private app data, and files containing complex app- or user-generated data. | Preferences and configuration data that can be expressed using simple data types. | Complex private app data and files, structured data, user-generated data, data that you want to share among users. |
| Entitlement keys | `com.apple.developer.` `icloud-services`, `com.apple.developer.` `icloud-container-identifiers` | `com.apple.developer.` `ubiquity-kvstore-identifier` | `com.apple.developer.` `icloud-services`, `com.apple.developer.` `icloud-container-identifiers` |
| Data format | Files and file packages | Property-list data types only (numbers, strings, dates, and so on) | Records, represented as collections of key-value pairs where values are a subset of property-list data types, files, or references to other records. |
| Capacity | Limited only by the space available in the user’s iCloud account. | Limited to a total of 1 MB per app, with a per-key limit of 1 MB. | Limited only by the space available in the user’s iCloud account (private database) and the app’s allotted storage quota (public database). |
| Detecting availability | Call the `URLForUbiquityContainerIdentifier:` method for one of your ubiquity containers. If the method returns `nil`, document storage is not available. | Key-value storage is effectively always available. If a device is not attached to an account, changes created on the device are pushed to iCloud as soon as the device is attached to the account. | The public database is always available. The private database is available only when the value in the `ubiquityIdentityToken` property is not `nil`. |
| Locating data | Use an `NSMetadataQuery` object to obtain live-updated information on available iCloud files. | Use the shared `NSUbiquitousKeyValueStore` object to retrieve values. | Use a `CKQuery` object with a `CKQueryOperation` to search for records matching the predicate you specify. Use other operation objects to fetch records by ID. |
| Managing data | Use the `NSFileManager` class to work directly with files and directories. | Use the default `NSUbiquitousKeyValueStore` object to manipulate values. | Use the classes of the CloudKit framework to manage data. |
| Resolving conflicts | Documents, as file presenters, automatically handle conflicts; in OS X, `NSDocument` presents versions to the user if necessary. For files, you manually resolve conflicts using file presenters. | The most recent value set for a key wins and is pushed to all devices attached to the same iCloud account. The timestamps provided by each device are used to compare modification times. | When saving records, assign an appropriate value to the `savePolicy` property of a `CKModifyRecordsOperation` object to specify how you want to handle conflicts. |

| Metadata transfer | Automatic, in response to local file system changes. | Not applicable (key-value storage doesn’t use metadata). | Not applicable |

**Table 1-1**  Differences between document and key-value storage

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2015-12-17

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Art/iCloud_intro_2x.png

�PNG


IHDR%���� pHYs��
OiCCPPhotoshop ICC profilexڝSgTS�=���BK���KoR RB���&\*! J�!��Q�EEȠ�����Q,�

�b@q��S�(R�jJ��4�e�2AU��Rݨ�T5�ZB���R�Q��4u�9̓IK�����hh�i��t�ݕN��W���G���w\
��ǈg(�gw��L�Ӌ�T071���oUX\*�\*\|��\
�J�&�\*/T����ުU�U�T��^S}�FU3S� Ԗ�U��P�SSg�;���g�oT?�~Y��Y�L�OC�Q��\_�� c�x,!k\
��u�5�&���\|v\*�����=���9C3J3W�R�f?�q��tN �(���~���)�)�4L�1e\\k����X�H�Q�G�6������E�Y��A�J'\\'Gg����S�Sݧ\
�M=:��.�k���Dw�n��^��Lo��y���}/�T�m���GX�$��<�5qo</���QC\]�@C�a�a�ᄑ��<��F�F�i�\\�$�m�mƣ&&!&KM�M�RM��)�;L;L���͢�֙5�=1�2��כ߷\`ZxZ,����eI��Z�Yn�Z9Y�XUZ\]�F���%ֻ�����N�N���gð�ɶ�����ۮ�m�}agbg�Ů��}�}��=

y��g"/�6ш�C\\\*N�H\*Mz�쑼5y$�3�,幄'���L
Lݛ:��v m2=:�1����qB�!M��g�g�fvˬe����n��/��k���Y-
�B��TZ(�\*�geWf�͉�9���+��̳�ې7�����ᒶ��KW-X潬j9�������(�x��oʿ�ܔ���Ĺd�f�f���-�\[����n\
�ڴ\

6\
U����#pDy��� ��\

�D��\*2\*�wD1iXY���Z@��Wʋ��GE��/Q {����עL�(��Sũ"\
��z�+W�t{fՌ��&��l\_3��DI�+L�\

3C�f��Zy�d�'q�@/� T�ZK��y����q�.��h5$h�-��A��J��H��ٻ�u ^�2�:fI�\|��QC����\*�K���7����\|�\_rM�<ҿU\*�6�J"���Ku1H���oqςrc�$�h��Kp&"��C�����b�~��G��l��öO#�\

�%ig\_��Y�N�(xT4������K��I\

����ۍ\
���YJ'��#����X2�g\[P���b�@�yGБ@Q�~��pHrx����,��\[\*Dz�G�\
C%B����8���?�x��L� � �S�~�O����dʁ����,�<����MC�ș���)���RvAE:��"TBDD�sr��k�:�g��w��~���W\
8��hcsP�����3S���mDh�}�I}����Oߪ��,O����bTb����\|k��^���\_��\\�\]Qg� ��Id�ӴJZܡO�����\*��\
ч�^�\_Q�T��QӅj�\]����S�q~��c�;���汬v9��X����l?RiKE�fg��H\|/qYV5���s1�K�\*i�W���D7J����Q/���kP%�{}NƖ�n�ݾ�U���,6�y{���9���K��u�LV��<�{�y�ֆ��)���t���m9��G��\|Bj��Z\\��e�A�7ND�\\��e�PVWq����6��L��\\Ziq���\[$4�}�7��ˊ�CQ��2�=�9�%��i�Т6ⒽE���˫TPf��\[e!��\|��X~��A$��y��P�3�@�xTQf�a�Q�N�f����f�zU��ж���(\
3���K��E�%0<л�����S���й���\
�y�J\
m��YGwnGuV�/��ԭM� +YJ�����Ys��J��\_dm���PI��)��S��Ob�{\[\]�t�e�z��2sEl\]��ԫ�5x7U���ދ���{Y$�4q��"k��=��j�Kڞ�)�gV<� �Hȳp��Vѳ#\*\*��'XG�cdQ����ͱ4�i$�Ņ����Օ,�5���<&��J� D����Լ���;s���j3k%:�U�����<��ܬŎ���\*��)���\\D��Ƹd��H�&�1��cZt��TVp����F�P%-�J��UMR�m�vM���U\[�\
E�P�U��:&��$�<�i�ͅ�����V\]ѱl��t���%{�DRۙ�\\�ƅ}�\_�#�+:�wrQ�զW�����R���%\[n�cG�Wt�4�����\\�C=)w׸7\]O8�SaC��5�ތ)�2���;����23��U����FY�C\\�2\_�Y$D��W'Տ���V�����ӪR�n���t�q\_ݽ����N����8�ڊJ�&�< zf$}�wk�JDo���1��ZEq����@:��ܶ��֨�����u����N<ӕ��H+��^Ui���8�CT괓����N��Ş4Ց��TZzm�X��6Tk���^���\

Ay����%.ʩ��HE\*Q�J�V�~:�"O؉�K\]��y�\|\*Q�Jv�.�9��܎g��B��\[(�Z �޹�?uh��O�?�֔ J��X�/ǻ�����j��\[�j��g�\`�"3і�ck^k@%W�Jv�<����Ҳ�T���n=��/lVHק�r zrNҜ)���:�ܬ�^Y�Ѭ�Q�-TPSG���8{�5\]�\*�UiK���λDD3�%���� v���ใm��ɛXƦN����C33��\]%�˫ˈS���V:1����W\

ج)��d�J;J;�N""�\*�\`8���͑�1��%B�K�ܕa������)"lL�JXo���\[���d��߲7�Ϊ���g���R�H�.��H��M���&Q}���R�i��� ���U{2V��\[)�.�/��8���Pe�\|\_�o��h4��-A��%͆��b!c\*9��������8N%�r}G�����M���Kj6j��gB��#�N2�������+)��8�̓��l���M��~���=��'d\
ta����%�X3M����dQ��#�������/\]��3���Sۡ��d�#1���'Wh�ƅ&�)������\\�o���\_a���\*ivJ�D��jק�x�,ǳ��\
�f\_\\Oz��eP��ǵ^z��3��(�\
ǎ�{����=�j��k�=#R��35Ѓ����"�Ӿ:���\_��k.CVMP�#'�g"\]\_��ŵC�{kP�=(��!��h=s�b(:g+!�J���H+i~����,���ًc�ʧ+�S�\]�$��3/ :����菱��Ob�x�TRP qr˒�2��t��K�ҟhsb7yTҜ+��g�02Qg���\_�~�b�naK!\

�rA�4�63"���$G�������K�.ӍGJ����\|�3�b\
�C%��d��3+\[e��U��oK�O"�O=.�a91�\]���\[�?x3b�4�Dl@$����\_��9�U�)��\\b�\
k�Ν+�n�iF�a�T}I�ȥ��V�A�A��p&��Dl����xMz���ȣ����+0\*o��X��z�\

�${V�L�M.3T���<@%��/Y�$���!��zT2�eN��J��{��15�ﬃ�G�����UL�x/B%R���\]��;\*���隻P���K�#&F�$a�)�¨b\*�a5ހ�Q�~��7Q���9}/T�0������ߢ!�ދ̣Wj�Y�T;��\_��X�{'T�p˕����Xq��P��/A�2�J���G}��\

�\\���J�d�yt'�b��Jص�5�$��^Xxu�\_�=��۠�d/t��\\�11�\[������L��XG�Z��\
;\*�J�b����z���²}�-\_"�N����&V0�DE2��W%\

�g�Z?4�t��4�1��Y":Z�x$t������#Q�=ሻcD/��Pr��0}f݈�;��W\*!���\\3�P2Ė/��b��\*!��%G�����Y��V%DDm援"��O!/�᫃xW Q�G=N}+�\_iȓ��^E�ը�������\`��t(����H$��\
���B�ܐ����֢\`����H�ЄJ@hz�T$��\
��\`Q�P��y�W@D���a\
1,k��B""��c0\| ��Wղ� �\_��^�cl.��I\_�Ԏ}��ᣁk��?��\` Oםn��b3:�\`ݍ��'1q8c\*� �Ζ��97�ذKX)D��4X�κ��Ű\
��P�k}Q�7�;{���L����\`�-���Eb�HX�2!w�������E?S���}DD�Oh��\]kX~Ed̗T���'0�;��^�Q��+ʎޮ��u߂+����"c\*ij�ya{���\]mPv�KwuЀh�DJ�H�y\\lq��'\
u笩��P�\

���"(@�P��q�5ZD���c�Q\

��ɵv�wWu�DDGf�N��n�"X!��)��۱�9�$��xhdL�s����W��\
�ǆ���tO@%)�{Dl3���X�z;�uRq, VM�q�vf�˷V�сa�f9��Wl��HȬ����+z�d�y�\_A�ㆦ���W��� �w���~S'C+�w�ֱ�$�h�V�(wv��J^D����Z͂Mc�'����K�J��R\|<�?X�:�+�9A%�f�t�n��� ����;�t�Xs\[-f&�:ݥ���K��\[ꎰ�\\���#3P�6F���I�k���JFF���D��o��M��܎����&/}�Ril�\[)z��b�&��3����I�\]�)���8���pV�ەepg��{&�\\x�Rq�p��y�kuO�L��p�w�obsw���RY�籎^,�E�~?�9���NZ�;\|SQ̛�8hv�\\�&��.?GִO�g^�W{���so���y��Z\
�9ԗ3iW,��֘�=���U�I2��}Z\]�)�xM����G����=�\

.���G�9�\|�;�����S�7IǨb���������ڞ�\
��dS8�O.ӞH�t��������\]7&UD�?\_���7%���3ק:?�"����~��:ɖ�����\]z�t���wٍ��<�)�EG�(���9� B���s7��"=�F�}��\]�N
\|��=��?�ON���r�D�U�bJC�kkG���J^��!��c��A�\|�o�b-��\_��1��<���1?0'O��I y�6rb{ل�g���Qღ��%�z ����R�zI�%�LE�1+��4��/ۯ�'M�ŵ�詎9

C&\*�q�ȨX�q��r$��o�!T"�N�O��/�������AGD�d�#��q^��!T"�C �<6<����1��C��{�Ⱥ��� �����j��4v�C'#D��D��M\]�۳�� g�3$uv0G
��/\]\]��;

���(
ho��
go�#d�l���ņ�)�,n�

-��zG"鹕��Yd:�z�-�\\\_����dM�'�GROt�93�2�J�͜cc�IIEo�1Y^Du�J4�U!�X(o��b5��GM�J�G����;��3��Ng2���B9�PGֽ7yw-:� �D�Y��z�W�}�T@��7K ��-��\|IkQ�91/�\

�Q�'�\*�r�\|=���X&��L�\_��0�p��\]
��a�xI�<���Ϭ~\]�dp4���%��;LD�,At� wE��6�7ɗ�N�N�ϗiP\\D�

������h�%���?M����iN�X6�%\_B��D��8ÿ5��k�f�N�xU�M��E�S���=@$\*-. ݩ�L#���,�J��q�S��M��T\
�(��Od�k\_F�%)�v����P�RX���\|��j��O���U���H9�O4B%Ja�{��;T� \|t,�kg҈���7C\[�bKK=T�^����N���qR�����-���vP� ����f�Vo�J���B9�-P �tu�T���\|�(�?�@% ��E�� T2�ػD���� �^"����P b\|���ƗL�G���~땗oCq��J�3��QIs�X����y����%�vT\
}�jQ s��1�P���d(�ҷ͝����)Uw\\���Y�(�U�+�� \*�R{���\_\
K�.�h�D%�\*W E���=<є�Y���C����cϜ�/g�x�p԰�R��t�EOD���Tv�J%\*�od������ �����ʧ\\T�J:�f�̟yn��r�8H�+�t��9�\\�4U�dZ;��t��U�(rM1���ߣ�;W�(�/\*?�}5�Do�h��J�j���S����m�xd�\]��g��BL�V��������� S��Iڗ�����ڦt}�\\�T�6H��u���랯��{�����&�Q�P�����ӷ��A2!�Wu^}ˉ9����9��\_:���\
<(y?C�u��Ϋw�ϹJ.I����yT�n�ݖ�ǿ�,�Wx�\|�Bb��~���jTg��ݤjhY��Ь+��L�\
�CZ�W�Eu����UB�G�qL�)d�P�C���?{����W�aZ�Q,���^"�N�k��G�׆#��N�h��uv�Y%<К�<��������X��frPFd4Q#���d�.���,Q~U�6I�\

jTr�:��E�v�n�}�V�n�?�\[��Z}��\]�ە�ԘǕ�/��\`M�$��P \*\*\*\*@Qhi��� �;\\�����)��z�7�� Z\\���$ ���.YPc�u�K� Z\\���:f�R�tL�P%���J\`2'd\[���\_��������A%Zjq=ѓĽ�s�%@�,xE�w�U���O\|\]\

߳��"���D�F�=.��t�lD���M�\

��ޗ4~�(\_$�x��R����,6��k!�-l\

5\*�F\_��ғ��Gj�Tzkk\*r΃4��hQYbw�cj��?��Sci.��5z;�;��@%\*'؎�hq��������ҏ���{�S���(jT�n�~4�;� ���и/�3�@�{�E���T��ڸ�m�D8�\
��K@ֹ�W2ݸ+\*\*!���J Z\\@%@%@%@%(��q9Mi�Y�\
T�F���hq\_�\
�����˨9P����4G�P P �K�<��L}�Txms\|�)���~T�#W�Ϗ���������\
��U��60@%@��߆\

---

# https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Introduction/Introduction.html

Framework

# UIKit

Construct and manage a graphical, event-driven user interface for your iOS, iPadOS, or tvOS app.

## Overview

UIKit provides a variety of features for building apps, including components you can use to construct the core infrastructure of your iOS, iPadOS, or tvOS apps. The framework provides the window and view architecture for implementing your UI, the event-handling infrastructure for delivering Multi-Touch and other types of input to your app, and the main run loop for managing interactions between the user, the system, and your app.

UIKit also includes support for animations, documents, drawing and printing, text management and display, search, app extensions, resource management, and getting information about the current device. You can also customize accessibility support, and localize your app’s interface for different languages, countries, or cultural regions.

UIKit works seamlessly with the SwiftUI framework, so you can implement parts of your UIKit app in SwiftUI or mix interface elements between the two frameworks. For example, you can place UIKit views and view controllers inside SwiftUI views, and vice versa.

To build a macOS app, you can use SwiftUI to create an app that works across all of Apple’s platforms, or use AppKit to create an app for Mac only. Alternatively, you can bring your UIKit iPad app to the Mac with Mac Catalyst.

## Topics

### Essentials

Adopting Liquid Glass

Find out how to bring the new material to your app.

UIKit updates

Learn about important changes to UIKit.

About App Development with UIKit

Learn about the basic support that UIKit and Xcode provide for your iOS and tvOS apps.

Secure personal data, and respect user preferences for how data is used.

### App structure

UIKit manages your app’s interactions with the system and provides classes for you to manage your app’s data and resources.

Manage life-cycle events and your app’s UI scenes, and get information about traits and the environment in which your app runs.

Organize your app’s data and share that data on the pasteboard.

Manage the images, strings, storyboards, and nib files that you use to implement your app’s interface.

Extend your app’s basic functionality to other parts of the system.

Display activity-based services to people.

Create a version of your iPad app that users can run on a Mac device.

### User interface

Views help you display content onscreen and facilitate user interactions; view controllers help you manage views and the structure of your interface.

Present your content onscreen and define the interactions allowed with that content.

Manage your interface using view controllers and facilitate navigation around your app’s content.

Use stack views to lay out the views of your interface automatically. Use Auto Layout when you require precise placement of your views.

Apply Liquid Glass to views, support Dark Mode in your app, customize the appearance of bars, and use appearance proxies to modify your UI.

Provide feed

Responders and gesture recognizers help you handle touches and other events. Drag and drop, focus, peek and pop, and accessibility handle other user interactions.

Encapsulate your app’s event-handling logic in gesture recognizers so that you can reuse that code throughout your app.

Simplify interactions with your app using menu systems, contextual menus, Home Screen quick actions, and keyboard shortcuts.

Bring drag and drop to your app by using interaction APIs with your views.

Support pointer interactions in your custom controls and views.

Handle user interactions like double tap and squeeze on Apple Pencil.

Navigate the interface of your UIKit app using a remote, game controller, or keyboard.

Make your UIKit apps accessible to everyone who uses iOS and tvOS.

### Graphics, drawing, and printing

UIKit provides classes and protocols that help you configure your drawing environment and render your content.

Create and manage images, including those that use bitmap and PDF formats.

Configure your app’s drawing environment using colors, renderers, draw paths, strings, and shadows.

Display the system print panels and manage the printing process.

### Text

In addition to text views that simplify displaying text in your app, UIKit provides custom text management and rendering that supports the system keyboards.

Display text, manage fonts, and check spelling.

Manage text storage and perform custom layout of text-based content in your app’s views.

Configure the system keyboard, create your own keyboards to handle input, or detect key presses on a physical keyboard.

Add support for Writing Tools to your app’s text views.

Configure text fields and custom views that accept text to handle input from Apple Pencil.

### Deprecated

Avoid using deprecated classes and protocols in your apps.

Review unsupported symbols and their replacements.

### Reference

This document describes constants that are used throughout the UIKit framework.

The UIKit framework defines data types that are used in multiple places throughout the framework.

The UIKit framework defines a number of functions, many of them used in graphics and drawing operations.

### Classes

`class UIColorEffect`

A visual effect that applies a solid color background.

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/AppleTV_PG/index.html

App Programming Guide for tvOS

On This Page

- Apple TV Hardware
- Traditional Apps
- Client-Server Apps
- Top Shelf
- Focus and Layered Images
- New tvOS Frameworks
- New User Interface Challenges
- Local Storage for Your App Is Limited
- Targeting Apple TV in Your Apps
- Adopting Light and Dark Themes
- Implementing Universal Purchase
- Creating a Background Audio App

## Apple TV and tvOS

With Apple TV on tvOS, users can now play games, use productivity and social apps, watch movies, and enjoy shared experiences. All of these new features bring new opportunities for developers.

tvOS is derived from iOS but is a distinct OS, including some frameworks that are supported only on tvOS. You’ll find that the familiarity of iOS development, combined with support for a shared, multiuser experience, opens up areas of possibilities for app development that you won’t find on iOS devices. You can create new apps or use your iOS code as a starting point for a tvOS app. Either way, you use tools (Xcode) and languages (Objective-C, Swift, and JavaScript) that you are already familiar with. This document describes the unique capabilities of Apple TV and provides pointers to in-depth information that will get you started developing a tvOS app.

When porting an existing project, you can include an additional target in your Xcode project to simplify sharing of resources, but you need to create new storyboards for tvOS. Likely, you will need to look at how users navigate through your app and adapt your app’s user interface to Apple TV. For more information, see _Apple TV Human Interface Guidelines_.

A new Apple TV-specific provisioning profile is required for Apple TV development and distribution, which is used with your existing iOS development and distribution signing identities. You create a new Apple TV provisioning profile the same way that you create an iOS provisioning profile, using Fix Issue in Xcode, or through the developer portal website. For information on capabilities supported by Apple TV, see Supported Capabilities.

Although iOS and tvOS apps are distinct entities (meaning there isn’t a single binary that runs on both platforms), you can create a universal purchase that bundles these apps. The user purchases an app once, and gets the iOS version for their iOS devices and a tvOS version for Apple TV. For more information, see _App Distribution Guide_.

### Apple TV Hardware

Apple TV has the following hardware specifications:

- 64-bit A8 processor

- 32 GB or 64 GB of storage

- 2 GB of RAM

- 10/100 Mbps Ethernet

- WiFi 802.11a/b/g/n/ac

- 1080p resolution

- HDMI

- New Siri Remote / Apple TV Remote

The Apple TV Remote comes in two flavors—one with Siri built in and the other with onscreen search capabilities. The Siri Remote is available in the following countries:

- Australia

- Canada

- France

- Germany

- Japan

- Spain

- United Kingdom

- United States

Apple TVs in all other countries are packaged with the Apple TV Remote. Figure 1-1 shows the new remote. It has the following buttons:

1. Touch surface. Swipe to navigate. Press to select. Press and hold for contextual menus.

2. Menu. Press to

### Traditional Apps

The process for creating apps for Apple TV is similar to the process for creating iOS apps. You can create games, utility apps, media apps, and more using the same techniques and frameworks used by iOS. New and existing apps can target both iOS and the new Apple TV, allowing for unprecedented multiplayer options.

### Client-Server Apps

Apple TV makes it easier to create client-server apps, whose primary purpose is to stream media, using web technologies such as HTTPS, XMLHTTPRequest, DOM, and JavaScript. You use Apple’s custom markup language, TVML, to create interfaces, and you specify app behaviors using JavaScript. The TVMLKit framework provides the bridge between your native code and the JavaScript code in your user interface.

You specify your app’s initial launch behavior in a JavaScript file. Create your binary app as you typically would, and then use the TVMLKit framework to load the JavaScript file. Your JavaScript file loads TVML pages and displays them on the screen. Create TVML pages using templates supplied by Apple. Each template produces a unique, full-screen display of information. You modify a page by adding or removing elements from a template. For a list of Apple-supplied TVML templates and elements, see _Apple TV Markup Language Reference_.

All video playback on Apple TV is based on HTTP Live Streaming and FairPlay Streaming. See _About HTTP Live Streaming_ and _FairPlay Streaming Overview_. For HTTP Live Streaming authoring specifications, see HLS Authoring Specification for Apple TV.

### Top Shelf

Users can place any Apple TV app in the top row of their app’s menu, which can contain up to five icons. When a user selects an app icon in the top row, the top of the screen shows content related to that app. This area is called the top shelf. The top shelf can showcase an app’s content, give people a preview of the content they care about, or let them jump straight into a particular part of the app.

### Focus and Layered Images

A UI element is _in focus_ when the user highlights an item, but has not selected an item. When a user brings focus to a layered image, the image responds to the user’s touches on the glass touch surface of the remote. Each layer of the image rotates at a slightly different rate to create a parallax effect. This subtle effect creates a sense of depth, realism, and vitality, and emphasizes that the focused item is the closest thing to the user.

Your layered images are going to be created by your designers. But how do you get them into your app? The `UIImageView` class has been modified to support layered images, so in most cases you only need to make minimal coding changes. Your workflow is going to change depending on whether you are adding the images directly to your app or loading them from a server at runtime.

### New tvOS Frameworks

Apple tvOS introduces the following new frameworks that are specific to tvOS:

- TVMLJS. Describes the JavaScript APIs used to load the TVML pages that are used to display information in client-server apps. See _Apple TV JavaScript Framework Reference_.

- TVMLKit. Provides a way to incorporate JavaScript and TVML elements into your app. See _TVMLKit Framework Reference_.

- TVServices. Describes how to add a top shelf extension to your app. See _TVServices Framework Reference_.

### New User Interface Challenges

Apple TV does not have a mouse that allows users to directly select and interact with an app, nor are users able to use gestures and touch to interact with an app. Instead, they use the new Siri Remote or a game controller to move around the screen.

In addition to the new controls, the overall user experience is drastically different. Macs and iOS devices are generally a single-person experience. A user may interact with others through your app, but that user is still the only person using the device. With the new Apple TV, the user experience becomes much more social. Several people can be sitting on the couch and interacting with your app and each other. Designing apps to take advantage of these changes is crucial to designing a great app.

### Local Storage for Your App Is Limited

The maximum size for a tvOS app bundle 4 GB. Moreover, your app can only access 500 KB of persistent storage that is local to the device (using the `NSUserDefaults` class). Outside of this limited local storage, all other data must be purgeable by the operating system when space is low. You have a few options for managing these resources:

- Your app can store and retrieve user data in iCloud.

- Your app can download the data it needs into its cache directory. Downloaded data is not deleted while the app is running. However, when space is low and your app is not running, this data may be deleted. Do not use the entire cache space as this can cause unpredictable results.

- Your app can package read-only assets using on-demand resources. Then, at runtime, your app requests the resources it needs, and the operating system automatically downloads and manages those resources. Knowing how and when to load new assets while keeping your users engaged is critical to creating a successful app. For information on on-demand resources, see _On-Demand Resources Guide_.

This means that every app developed for the new Apple TV must be able to store data in iCloud and retrieve it in a way that provides a great customer experience.

### Targeting Apple TV in Your Apps

To conditionalize code so that it is only compiled for tvOS, use the `TARGET_OS_TV` macro or one of the tvOS version constants defined in `Availability.h`. In an app written in Swift, use a build configuration statement or an API availability statement.

**Listing 1-1** Conditionalizing code for tvOS in Objective-C

1. `#if TARGET_OS_TV

2. ` NSLog(@"Code compiled only when building for tvOS.");

3. `#endif

**Listing 1-2** Conditionalizing code for tvOS in Swift

1. `#if os(tvOS)`
2. `NSLog(@"Code compiled only when building for tvOS.");`
3. `#endif`
4. ` `
5. `if #available(tvOS 9.1,*) {`
6. ` print("Code that executes only on tvOS 9.1 or later.")`
7. `}`

### Adopting Light and Dark Themes

Starting in tvOS 10.0, you are able to personalize your app using light and dark themes. Apps automatically adopt a light theme unless you specifically tell your app to adopt dark themes. To adopt a dark theme, set the UIUserInterfaceStyle property in your apps info.plist to either `Dark` or `Automatic`. If you create a new app using Xcode 8.0, the UIUserInterfaceStyle property is automatically set to `Automatic`.

### Implementing Universal Purchase

By linking the iOS and tvOS versions of your app in iTunes Connect, you can enable universal purchase for your app. Universal purchase allows users to download both iOS and tvOS versions of your app with a single purchase, providing a seamless experience for your users. See Universal Purchase of iOS and tvOS Apps to learn how to set up universal purchase.

### Creating a Background Audio App

You must declare that your tvOS app provides specific background services and must be allowed to continue running while in the background. To do this, add the `UIBackgroundModes` key in your app’s `info.plist` file. The key’s value is an array that contains one or more strings identifying which background tasks your app supports. Specify the string value `audio` to indicate your app plays audible content to the user while in the background.

Creating a Client-Server App

[](http://www.apple.com/legal/terms/site.html) \|
[](http://www.apple.com/privacy/) \|
Updated: 2017-01-12

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/MOSXAppProgrammingGuide/Introduction/Introduction.html

Documentation Archive Developer

Search

Search Documentation Archive

Next

# About OS X App Design

This document is the starting point for learning how to create Mac apps. It contains fundamental information about the OS X environment and how your apps interact with that environment. It also contains important information about the architecture of Mac apps and tips for designing key parts of your app.

## At a Glance

Cocoa is the application environment that unlocks the full power of OS X. Cocoa provides APIs, libraries, and runtimes that help you create fast, exciting apps that automatically inherit the beautiful look and feel of OS X, as well as standard behaviors users expect.

### Cocoa Helps You Create Great Apps for OS X

You write apps for OS X using Cocoa, which provides a significant amount of infrastructure for your program. Fundamental design patterns are used throughout Cocoa to enable your app to interface seamlessly with subsystem frameworks, and core application objects provide key behaviors to support simplicity and extensibility in app architecture. Key parts of the Cocoa environment are designed particularly to support ease of use, one of the most important aspects of successful Mac apps. Many apps should adopt iCloud to provide a more coherent user experience by eliminating the need to synchronize data explicitly between devices.

### Common Behaviors Make Apps Complete

During the design phase of creating your app, you need to think about how to implement certain features that users expect in well-formed Mac apps. Integrating these features into your app architecture can have an impact on the user experience: accessibility, preferences, Spotlight, services, resolution independence, fast user switching, and the Dock. Enabling your app to assume full-screen mode, taking over the entire screen, provides users with a more immersive, cinematic experience and enables them to concentrate fully on their content without distractions.

### Get It Right: Meet System and App Store Requirements

Configuring your app properly is an important part of the development process. Mac apps use a structured directory called a _bundle_ to manage their code and resource files. And although most of the files are custom and exist to support your app, some are required by the system or the App Store and must be configured properly. The application bundle also contains the resources you need to provide to internationalize your app to support multiple languages.

### Finish Your App with Performance Tuning

As you develop your app and your project code stabilizes, you can begin performance tuning. Of course, you want your app to launch and respond to the user’s commands as quickly as possible. A responsive app fits easily into the user’s workflow and gives an impression of being well crafted. You can improve the performance of your app by speeding up launch time and decreasing your app’s code footprint.

## How to Use This Document

This guide introduces you to the most important technologies that go into writing an app. In this guide you will see the whole landscape of what's needed to write one. That is, this guide shows you all the "pieces" you need and how they fit together. There are important aspects of app design that this guide does not cover, such as user interface design. However, this guide includes many links to other documents that provide details about the technologies it introduces, as well as links to tutorials that provide a hands-on approach.

In addition, this guide emphasizes certain technologies introduced in OS X v10.7, which provide essential capabilities that set your app apart from older ones and give it remarkable ease of use, bringing some of the best features from iOS to OS X.

## See Also

The following documents provide additional information about designing Mac apps, as well as more details about topics covered in this document:

- To work through a tutorial showing you how to create a Cocoa app, see _Start Developing Mac Apps Today_.

- For information about user interface design enabling you to create effective apps using OS X, see _OS X Human Interface Guidelines_.

- To understand how to create an explicit app ID, create provisioning profiles, and enable the correct entitlements for your application, so you can sell your application through the Mac App Store or use iCloud storage, see _App Distribution Guide_.

- For a general survey of OS X technologies, see _Mac Technology Overview_.

- To understand how to implement a document-based app, see _Document-Based App Programming Guide for Mac_.

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2015-03-09

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/DocumentBasedAppPGiOS/Introduction/Introduction.html

Documentation Archive Developer

Search

Search Documentation Archive

Next

# About Document-Based Applications in iOS

The UIKit framework offers support for applications that manage multiple documents, with each document containing a unique set of data that is stored in a file located either in the application sandbox or in iCloud.

Central to this support is the `UIDocument` class, introduced in iOS 5.0. A document-based application must create a subclass of `UIDocument` that loads document data into its in-memory data structures and supplies `UIDocument` with the data to write to the document file. `UIDocument` takes care of many details related to document management for you. Besides its integration with iCloud, `UIDocument` reads and writes document data in the background so that your application’s user interface does not become unresponsive during these operations. It also saves document data automatically and periodically, freeing your users from the need to explicitly save.

## At a Glance

Although a document-based application is responsible for a range of behaviors, making an application document-based is usually not a difficult task.

### Document Objects Are Model Controllers

In the Model-View-Controller design pattern, document objects—that is, instances of subclasses of `UIDocument`—are model controllers. A document object manages the data associated with a document, specifically the model objects that internally represent what the user is viewing and editing. A document object, in turn, is typically managed by a view controller that presents a document to users.

**Relevant Chapter:** Designing a Document-Based Application

### When Designing an Application, Consider Document-Data Format and Other Issues

Before you write a line of code you should consider aspects of design specific to document-based applications. Most importantly, what is the best format of document data for your application, and how can you make that format work for your application in iOS _and_ Mac OS X? What is the most appropriate document type?

You also need to plan for the view controllers (and views) managing such tasks as opening documents, indicating errors, and moving selected documents to and from iCloud storage.

**Relevant Chapters:** Designing a Document-Based Application, Document-Based Application Preflight

### Creating a Subclass of UIDocument Requires Two Method Overrides

The primary role of a document object is to be the “conduit” of data between a document file and the model objects that internally represent document data. It gives the `UIDocument` class the data to write to the document file and, after the document file is read, it initializes its model objects with the data that `UIDocument` gives it. To fulfill this role, your subclass of `UIDocument` must override the `contentsForType:error:` method and the `loadFromContents:ofType:error:` method, respectively.

**Relevant Chapter:** Creating a Custom Document Object

### An Application Manages a Document Through Its Life Cycle

An application is responsible for managing the following events during a document’s lifetime:

- Creation of the document

- Opening and closing the document

- Monitoring changes in document state and responding to errors or version conflicts

- Moving documents to iCloud storage (and removing them from iCloud storage)

- Deletion of the document

**Relevant Chapter:** Managing the Life Cycle of a Document

### An Application Stores Document Files in iCloud Upon User Request

Applications give their users the option for putting all document files in iCloud storage or all document files in the local sandbox. To move document files to iCloud, they compose a file URL locating the document in an iCloud container directory of the application and then call a specific method of the `NSFileManager` class, passing in the file URL. Moving document files from iCloud storage to the application sandbox follows a similar procedure.

### An Application Ensures That Document Data is Saved Automatically

`UIDocument` follows the saveless model and automatically saves a document’s data at specific intervals. A user usually never has to save a document explicitly. However, your application must play its part in order for the saveless model to work, either by implementing undo and redo or by tracking changes to the document.

**Relevant Chapter:** Change Tracking and Undo Operations

### An Application Resolves Conflicts Between Different Document Versions

When documents are stored in iCloud, conflicts between versions of a document can occur. When a conflict occurs, UIKit informs the application about it. The application must attempt to resolve the conflict itself or invite the user to pick the version he or she prefers.

**Relevant Chapter:** Resolving Document Version Conflicts

## How to Use This Document

Before you start writing any code for your document-based application, you should at least read the first two chapters, Designing a Document-Based Application and Document-Based Application Preflight. These chapters talk about design and configuration issues, and give you an overview of the tasks required for well-designed document-based applications

## Prerequisites

Before you read _Document-Based Application Programming Guide for iOS_ you should become familiar with the information presented in _App Programming Guide for iOS_.

## See Also

The following documents are related in some way to _Document-Based Application Programming Guide for iOS_:

- _Uniform Type Identifiers Overview_ and the related reference discuss Uniform Type Identifiers (UTIs), which are the primary identifiers of document types.

- _File Metadata Search Programming Guide_ describes how to conduct searches using the `NSMetadataQuery` class and related classes. You use metadata queries to locate an application’s documents stored in iCloud.

- _iCloud Design Guide_ provides an introduction to iCloud document support.

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2012-09-19

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/DocBasedAppProgrammingGuideForOSX/Introduction/Introduction.html

Documentation Archive Developer

Search

Search Documentation Archive

Next

# About the Cocoa Document Architecture

In OS X, a Cocoa subsystem called the _document architecture_ provides support for apps that manage documents, which are containers for user data that can be stored in files locally and in iCloud.

## At a Glance

Document-based apps handle multiple documents, each in its own window, and often display more than one document at a time. Although these apps embody many complex behaviors, the document architecture provides many of their capabilities “for free,” requiring little additional effort in design and implementation.

### The Model-View-Controller Pattern Is Basic to a Document-Based App

The Cocoa document architecture uses the Model-View-Controller (MVC) design pattern in which model objects encapsulate the app’s data, view objects display the data, and controller objects act as intermediaries between the view and model objects. A document, an instance of an `NSDocument` subclass, is a controller that manages the app’s data model. Adhering to the MVC design pattern enables your app to fit seamlessly into the document architecture.

### Xcode Supports Coding and Configuring Your App

Taking advantage of the support provided by Xcode, including a document-based application template and interfaces for configuring app data, you can create a document-based app without having to write much code. In Xcode you design your app’s user interface in a graphical editor, specify entitlements for resources such as the App Sandbox and iCloud, and configure the app’s property list, which specifies global app keys and other information, such as document types.

### You Must Subclass NSDocument

Document-based apps in Cocoa are built around a subclass of `NSDocument` that you implement. In particular, you must override one document reading method and one document writing method. You must design and implement your app’s data model, whether it is simply a single text-storage object or a complex object graph containing disparate data types. When your reading method receives a request, it takes data provided by the framework and loads it appropriately into your object model. Conversely, your writing method takes your app’s model data and provides it to the framework’s machinery for writing to a document file, whether it is located only in your local file system or in iCloud.

### NSDocument Provides Core Behavior and Customization Opportunities

The Cocoa document architecture provides your app with many built-in features, such as autosaving, asynchronous document reading and writing, file coordination, and multilevel undo support. In most cases, it is trivial to opt-in to these behaviors. If your app has particular requirements beyond the defaults, the document architecture provides many opportunities for extending and customizing your app’s capabilities through mechanisms such as delegation, subclassing and overriding existing methods with custom implementations, and integration of custom objects.

## Prerequisites

Before you read this document, you should be familiar with the information presented in _Mac App Programming Guide_.

## See Also

See _Document-Based App Programming Guide for iOS_ for information about how to develop a document-based app for iOS using the `UIDocument` class.

For information about iCloud, see _iCloud Design Guide_.

_File Metadata Search Programming Guide_ describes how to conduct searches using the `NSMetadataQuery` class and related classes. You use metadata queries to locate an app’s documents stored in iCloud.

For information about how to publish your app in the App Store, see _App Distribution Guide_.

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2012-12-13

---

# https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/index.html

Core Data Programming Guide

## What Is Core Data?

Core Data is a framework that you use to manage the model layer objects in your application. It provides generalized and automated solutions to common tasks associated with object life cycle and object graph management, including persistence.

Core Data typically decreases by 50 to 70 percent the amount of code you write to support the model layer. This is primarily due to the following built-in features that you do not have to implement, test, or optimize:

- Change tracking and built-in management of undo and redo beyond basic text editing.

- Maintenance of change propagation, including maintaining the consistency of relationships among objects.

- Lazy loading of objects, partially materialized futures (faulting), and copy-on-write data sharing to reduce overhead.

- Automatic validation of property values. Managed objects extend the standard key-value coding validation methods to ensure that individual values lie within acceptable ranges, so that combinations of values make sense.

- Schema migration tools that simplify schema changes and allow you to perform efficient in-place schema migration.

- Optional integration with the application’s controller layer to support user interface synchronization.

- Grouping, filtering, and organizing data in memory and in the user interface.

- Automatic support for storing objects in external data repositories.

- Sophisticated query compilation. Instead of writing SQL, you can create complex queries by associating an NSPredicate object with a fetch request.

- Version tracking and optimistic locking to support automatic multiwriter conflict resolution.

- Effective integration with the macOS and iOS tool chains.

Creating a Managed Object Model

[](http://www.apple.com/legal/terms/site.html) \|
[](http://www.apple.com/privacy/) \|
Updated: 2017-03-27

---

# https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/UsingCoreDataWithiCloudPG/Introduction/Introduction.html

Documentation Archive Developer

Search

Search Documentation Archive

Next

# Retired Document

**Important:**
The use of iCloud with Core Data has been deprecated and is no longer being supported.

# About Using iCloud with Core Data

iCloud is a cloud service that gives your users a consistent and seamless experience across all of their iCloud-enabled devices. iCloud works with ubiquity containers—special folders that your app stores data in—to manage your app’s cloud storage. When you add, delete, or make changes to a file in your app’s ubiquity container, the system uploads the changes to iCloud. Other peers download the changes to keep your app up to date.

To help you persist managed objects to the cloud, iCloud is integrated with Core Data. To use Core Data with iCloud, you simply tell Core Data to create an iCloud-enabled persistent store. The iCloud service and Core Data take care of the rest: The system manages the files in the ubiquity container that make up your persistent store, and Core Data helps you keep your app up to date. To let you know when the content in your container changes, Core Data posts notifications.

## At a Glance

When you use Core Data, you have several storage models to choose from. Using Core Data with iCloud, you have a subset of these options, as follows:

- Atomic stores (for example, the binary store) load and save all of your managed objects in one go. Atomic stores work best for smaller storage requirements.

- Transactional stores (for example, the SQLite store) load and save only the managed objects that you’re using and offer high–performance querying and merging. Transactional stores work best for larger, more complex storage requirements.

- Document storage (iOS only) works best for apps designed to use a document-based design paradigm. Use document storage in combination with either an atomic or a transactional store.

When you decide on a storage model, consider the strengths of each store as well as the iCloud-specific strengths discussed below.

### Use Core Data Atomic Stores for Small, Simple Storage

iCloud supports XML (OS X only) and binary atomic persistent stores. Useful for small, simple storage requirements, Core Data’s atomic-store support sacrifices merging and network efficiency for simplicity of use for when your data rarely changes. When you use iCloud with an atomic persistent store, you work directly in the ubiquity container. Binary (and XML) store files are themselves transferred to the iCloud servers; so whenever a change is made to the data, the system uploads the entire store and pushes it to all connected devices. This means that changes on one peer can overwrite changes made on the others.

iCloud treats Core Data atomic stores like any other file added to your app’s ubiquity container. You can learn more about managing files in your app’s ubiquity container in _iCloud Design Guide_.

### Use Core Data Transactional Stores for Large, Complex Storage

Core Data provides ubiquitous persistent storage for SQLite-backed stores. Core Data takes advantage of the SQLite transactional persistence mechanism, saving and retrieving transaction logs—logs of changes—in your app’s ubiquity container. The Core Data framework’s reliability and performance extend to iCloud, resulting in dependable, fault-tolerant storage across multiple peers. Continue reading this document to learn more about how to use iCloud with an SQLite store.

### (iOS Only) Use Core Data Document Stores to Manage Documents in iCloud

The `UIManagedDocument` class is the primary mechanism through which Core Data stores managed documents in iCloud on iOS. The `UIManagedDocument` class manages the entire Core Data stack for each document in a document-based app. Changes to managed documents are automatically persisted to iCloud. By default, managed documents are backed by SQLite-type persistent stores, but you can choose to use atomic stores instead. While the steps you take to integrate the `UIManagedDocument` class into your app differ, the model-specific guidelines and best practices you follow are generally the same. You can find additional implementation strategies and tips in Using Document Storage with iCloud.

## Prerequisites

iCloud is a service that stores your app’s data in the cloud and makes it available to your users’ iCloud-enabled devices. Before using Core Data’s iCloud integration, you should read more about iCloud in _iCloud Design Guide_. In addition, this guide assumes a working knowledge of Core Data, a powerful object graph and data persistence framework. For more information about the Core Data framework, see Introduction to Core Data Programming Guide in _Core Data Programming Guide_.

* * *

[](http://www.apple.com/legal/internet-services/terms/site.html) \| [](http://www.apple.com/privacy/) \| Updated: 2017-06-06

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html)

View in English#)

# The page you’re looking for can’t be found.

---

# https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Art/iCloud_intro_2x.png)



---

