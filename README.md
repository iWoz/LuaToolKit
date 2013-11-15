##lua2xml.lua
这个工具用来将xml文件导出成table表以储存在lua文件内,这样可以给数据的读取变得更快更方便。

使用这个工具时，xml文件内需要规定主键，写在primeKey字段内。主键可以有多个，彼此之间用"_"进行分隔。

目前不支持多层嵌套的xml。

##h2pkg.lua
这个工具用来进行lua binding的准备工作，即将头文件.h转成.pkg，以供tolua++进行binding。

在面对大量需要处理的.h文件时，手工转是件杀死眼睛累死手的差事。所以写了这个工具以提供自动化处理，当然由于判断条件不是非常完备，可能存在一些bug。

##主页

<http://wuzhiwei.net/opensrc/LuaToolKit/luaToolKit.html>
