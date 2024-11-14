-------------
--root.lua
--------------
lock.singleton() -- 二重起動の禁止

-------------------------------
-- システムのロード
-------------------------------
archive.dofile("system.lua")

-------------------------------
-- 動作設定
-------------------------------
gui.create(1024,768)      -- 画面の大きさを変えたい場合はこの数字を弄る。コンソールアプリを作る場合はこの行を削除。
basic.utf8_flag=0         -- これを1にすれば、BASICスクリプトをUTF-8で書けます。
basic.textautopauseflag=1 -- これを0にすれば、表示文の文末に自動で\pが補われなくなります。
basic.pad_enable=0        -- 1にするとXBOXパッド入力が有効になります（ボタン機能等の実装は自前で行う必要があります） nscr2pad.dllが必要です。
basic.backlogsize=50      -- バックログのサイズ。行単位。

-------------------------------
-- メインルーチン
-------------------------------
function main ()
	--BASICのソースファイルのロード
	for i=0,99 do
		local fname=string.format("%02d.txt",i)
		if archive.seek(fname) then
			local str=archive.read("\n")
			if basic.utf8_flag==0 then
				str=encoding.ansi_to_utf8(str)
			end
			basic.loadscript(fname,str)
		end
	end

	--BASICの実行
	basic.run() -- 無限ループ
end



--プログラム実行(このファイルの最後にすること。無限ループのため、ここより下は実行されないことになるので）
main()

