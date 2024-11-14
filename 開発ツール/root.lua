--このように、BASICを起動させないプログラムも書けます。NScripter2の内部関数を使って処理をしています。

function NS2Archive()
	console.print("■NS2アーカイブ作成■")
	console.print("圧縮するフォルダを選択してください。全角文字の含まれたフォルダ名やファイル名は使わないでください。")
	dir=gui.dirdialog()
	if dir==nil then return end
	console.print("保存ファイル名を指定してください。NScripter2は00.ns2～99.ns2に対応しており、同一ファイル名の場合大きい番号のアーカイブにあるものが優先です。また、連番である必要はありません。")
	local fn=gui.savedialog("ns2","00.ns2")
	if fn==nil then return end
	local ufn=encoding.ansi_to_utf8(fn)
	local udir=encoding.ansi_to_utf8(dir)
	console.print("ファイル名\""..ufn.."\"（圧縮対象フォルダ\""..udir.."\"）の処理を開始します。")
	encoding.createarchive(fn,dir,true)
	console.print("ファイル名\""..ufn.."\"（圧縮対象フォルダ\""..udir.."\"）の処理を完了しました。")
	os.execute("pause")
end

function PNGtoANMV()
	console.print("■連番PNGをα値付きNMV形式に変換■")
	console.print("連番PNGを格納したフォルダを選択してください。")
	dir=gui.dirdialog()
	if dir==nil then return end
	console.print("保存ファイル名を指定してください。")
	local fn=gui.savedialog("nmv")
	if fn==nil then return end
	console.write ("フレームレートを入力してください。\n> ")
	local fps=tonumber(console.readline())
	if fps==nil then return end
	console.print("品質を入力してください(0-100)")
	console.write("> ")
	local q=tonumber(console.readline())
	if q==nil then return end
	local ufn=encoding.ansi_to_utf8(fn)
	local udir=encoding.ansi_to_utf8(dir)
	console.print("ファイル名\""..ufn.."\"（対象フォルダ\""..udir.."\"）の処理を開始します。")
	local tbl=gui.getfilelist(dir,"png")
	table.sort(tbl)
	local firstflag=true
	local framenum=0
	for i,v in ipairs(tbl) do
		if v:sub(-3):lower()=="png" then
			framenum=framenum+1
		end
	end
	for i,v in ipairs(tbl) do
		console.print (encoding.ansi_to_utf8(v).."を処理しています。")
		if v:sub(-3):lower()=="png" then
			bmp=bitmap.load(dir..v)
			if firstflag then
				local w,h=bmp:getsize()
				nmv.writebegin(fn,w*2,h,fps,framenum,q)
				firstflag=false
			end
			bmp:expandalpha()
			nmv.write(bmp)
		end
	end
	nmv.writeend()
	console.print("ファイル名\""..ufn.."\"（対象フォルダ\""..udir.."\"）の処理を完了しました。")
	os.execute("pause")
end

function PNGtoNMV()
	console.print("■連番PNGをα値無しのNMV形式に変換■")
	console.print("連番PNGを格納したフォルダを選択してください。")
	dir=gui.dirdialog()
	if dir==nil then return end
	console.print("保存ファイル名を指定してください。")
	local fn=gui.savedialog("nmv")
	if fn==nil then return end
	console.write ("フレームレートを入力してください。\n> ")
	local fps=tonumber(console.readline())
	if fps==nil then return end
	console.print("品質を入力してください(0-100)")
	console.write("> ")
	local q=tonumber(console.readline())
	if q==nil then return end
	local ufn=encoding.ansi_to_utf8(fn)
	local udir=encoding.ansi_to_utf8(dir)
	console.print("ファイル名\""..ufn.."\"（対象フォルダ\""..udir.."\"）の処理を開始します。")
	local tbl=gui.getfilelist(dir,"png")
	table.sort(tbl)
	local firstflag=true
	local framenum=0
	for i,v in ipairs(tbl) do
		if v:sub(-3):lower()=="png" then
			framenum=framenum+1
		end
	end
	for i,v in ipairs(tbl) do
		console.print (encoding.ansi_to_utf8(v).."を処理しています。")
		if v:sub(-3):lower()=="png" then
			bmp=bitmap.load(dir..v)
			if firstflag then
				local w,h=bmp:getsize()
				nmv.writebegin(fn,w,h,fps,framenum,q)
				firstflag=false
			end
			nmv.write(bmp)
		end
	end
	nmv.writeend()
	console.print("ファイル名\""..ufn.."\"（対象フォルダ\""..udir.."\"）の処理を完了しました。")
	os.execute("pause")
end

function JPEGtoNMV()
	console.print("■連番JPEGをα値無しのNMV形式に変換■")
	console.print("連番JPEGを格納したフォルダを選択してください。")
	dir=gui.dirdialog()
	if dir==nil then return end
	console.print("保存ファイル名を指定してください。")
	local fn=gui.savedialog("nmv")
	if fn==nil then return end
	console.write ("フレームレートを入力してください。\n> ")
	local fps=tonumber(console.readline())
	if fps==nil then return end
	local ufn=encoding.ansi_to_utf8(fn)
	local udir=encoding.ansi_to_utf8(dir)
	console.print("ファイル名\""..ufn.."\"（対象フォルダ\""..udir.."\"）の処理を開始します。")
	local tbl=gui.getfilelist(dir,"jpg")
	local tbl2=gui.getfilelist(dir,"jpeg")
	for i,v in ipairs(tbl2) do
		tbl[#tbl+1]=v
	end
	table.sort(tbl)

	local firstflag=true
	local framenum=0
	local framenum=0
	for i,v in ipairs(tbl) do
		if v:sub(-4):lower()=="jpeg" or v:sub(-3):lower()=="jpg" then
			framenum=framenum+1
		end
	end

	for i,v in ipairs(tbl) do
		console.print (encoding.ansi_to_utf8(v).."を処理しています。")
		if v:sub(-4):lower()=="jpeg" or v:sub(-3):lower()=="jpg" then
			if firstflag then
				bmp=bitmap.load(dir..v)
				local w,h=bmp:getsize()
				nmv.writebegin(fn,w,h,fps,framenum,100) -- 品質は使わないので
				firstflag=false
			end
			nmv.writejpeg(dir..v)
		end
	end
	nmv.writeend()
	console.print("ファイル名\""..ufn.."\"（対象フォルダ\""..udir.."\"）の処理を完了しました。")
	os.execute("pause")
end


console.print("---------------------------------")
console.print("-- NScripter2 開発用ツール")
console.print("---------------------------------")
while true do
	console.print("\n■MENU■")
	console.print("0:終了する")
	console.print("1:ns2アーカイブ作成")
	console.print("2:連番JPEGをα値無しのNMV形式に変換（高速）")
	console.print("3:連番PNGをα値付きNMV形式に変換")
	console.print("4:連番PNGをα値無しのNMV形式に変換")
	console.print("NMVファイルをこのウィンドウにドロップしてリターン→NMV再生テスト")
	console.print("")
	console.write("> ")
	str=console.readline()
	if str:match("nmv") then
		str=encoding.utf8_to_ansi(str:sub(1,-3))--\r\n削除
		local w,h=nmv.getinfo(str)
		if w then
			gui.create(w,h)
			while true do
				movie.play(str,0,0)
			end
		else
			console.print("NMVファイルが壊れています。")
		end
	end
	num=tonumber(str)
	if num==0 then
		os.exit(0)
	elseif num==1 then
		NS2Archive()
	elseif num==2 then
		JPEGtoNMV()
	elseif num==3 then
		PNGtoANMV()
	elseif num==4 then
		PNGtoNMV()
	end
end
