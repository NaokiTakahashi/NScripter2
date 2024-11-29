------------------
-- 【system.lua】
------------------

--このファイルを編集すると、今後のエンジンのバージョンアップと不整合を起こす可能性があります。
--Luaでどう機能を実装しているか調べるために、基本的には閲覧用で使ってください。

-----------------------
-- 様々な宣言
-----------------------
local VERSION=1.22 -- バージョン
local DIVISION=32  -- BASICにおける曲線の分割数
local SLEEP_TIME=4 -- フレームの間にSLEEPする時間。CPUを占有しないために最低でも1はほしい。ウェイト系命令の分解能でもある。
local HFCHAR=encoding.utf8_to_utf16("，．、。！？」）｝］)}]』,.!?ゃゅょャュョゎヮぁぃぅぇぉァィゥェォヶヵ゛゜")--行頭禁則文字
local HLCHAR=encoding.utf8_to_utf16("「（｛［({[『―‥・")--行末禁則文字（分離禁則もとりあえずこの扱いにしてある）

------------------
-- 終了処理
------------------

basic.registercom("QUIT","")
function basic_func.QUIT()
	gui.exit(0)
end

------------------
--basicモジュール
------------------

function basic.number_to_boolean (num)
	if num and num~=0 then return true else return false end
end

--------------------------------------------------------------------
--BASICの基本機能
--------------------------------------------------------------------
--BASICの動作に関するフラグ
basic.error_undefined_variable=true -- 未定義変数を参照するとエラーが出るようにするフラグ。基本trueで。

--その他変数
basic.backlog={}
basic.backlogheader=1
basic.texture={}
basic.bitmap={}
basic.sound={}
basic.bgmname=""
basic.bgvname={}
basic.seloopname={}
basic.fontparam={}
basic.fontstr={}
basic.spriteset={}
basic.set_attr={}
basic.filelog={}
basic.data={} -- その他細かいデータ
basic.data.bgmvol=0
basic.data.voicevol=0
basic.data.sevol=0
basic.data.bgvvol=0
basic.data.bgmfadeout=1000
basic.data.sefadeout=250
basic.data.bgvfadeout=250
basic_filter={} -- 現在のfilterは非推奨機能です。ロード時に予め画像をモノトーン化したりネガポジ反転したり出来ます。
basic.filter_handle=0
basic.btndefstr={}
basic.skippause=0 -- ノベルモードで改ページ待ち以外のクリック待ちをスキップするフラグ

basic.novelmode=0 -- ノベルモードフラグ (エンジンexeから読まれます）
basic.clearflag=true -- ノベルモードにおける改ページフラグ(エンジンexeから読まれます）

local btn_f={} -- ボタン用テーブル（効果音をここに格納したりしている）
btn_f.btnse=sound.create()

--------------------------------------------------------------------
-- ■■各命令・関数の実装■■
--------------------------------------------------------------------
------------------------------------
-- その他
------------------------------------
basic.registerfunc("GETVERSION","")
function basic_func.GETVERSION()
	return VERSION
end

basic.registerfunc("FILECHK","S")
function basic_func.FILECHK(fn)
	if archive.seek(fn) then
		return 1
	else
		return 0
	end
end

basic.registerfunc("ZLEN","S")
function basic_func.ZLEN(s)
	local tmp=encoding.utf8_to_utf16(s)
	return #tmp
end

------------------------------------
-- クリップボード
------------------------------------
basic.registercom("SETCLIPBOARD","S")
function basic_func.SETCLIPBOARD(text)
	gui.setclipboard(text)
end

------------------------------------
-- 選択肢・表示文・バックログ
------------------------------------

local lastlog

--特殊：basic.textは表示文に対応しています。登録の必要はありません。
function basic.text(stag,stext)
	if stag==nil and stext==nil then return end
	local logtbl={tag=stag,text=stext}
	basic.backlog[basic.backlogheader]=logtbl
	lastlog=basic.backlog[basic.backlogheader]
	basic.backlogheader=basic.backlogheader+1
	if basic.backlogheader>basic.backlogsize then basic.backlogheader=1 end
	basic.exec_call("@text",stag,stext)
end

basic.registercom("SELECT","S.")
function basic_func.SELECT (...)
	local param={...}
	if (#param%2) ~= 0 then error("SELECTの引数は選択肢テキスト,飛び先ラベル,...です。") end
	local cnum=math.floor(#param/2)
	-- param[N*2-1] ... 選択肢テキスト
	-- param[N*2] ... 選択肢飛び先ラベル basic.return(label)での飛び先に使う。
	basic.exec_call("@selectb",cnum,unpack(param))
end

basic.registerfunc("LOGCHK","N")
function basic_func.LOGCHK(num)
	local tag,text
	if num<0 or num>basic.backlogsize-1 then return 0 end
	local n=basic.backlogheader-1-num
	if n<1 then n=n+basic.backlogsize end
	if n<1 or n>basic.backlogsize then
		return 0
	else
		if basic.backlog[n]==nil then return 0 else return 1 end
	end
end

basic.registercom("GETLOGTEXT","NRR")
function basic_func.GETLOGTEXT(num,vtag,vtext)
	local tag,text
	local n=basic.backlogheader-1-num
	if n<1 then n=n+basic.backlogsize end
	if n<1 or n>basic.backlogsize then
		tag="#NIL"
		text="#NIL"
	else
		if basic.backlog[n]==nil then
			tag="#NIL"
			text="#NIL"
		else
			tag=basic.backlog[n].tag
			text=basic.backlog[n].text
		end
	end
	basic.vset(vtag,tag)
	basic.vset(vtext,text)
end


------------------------------------
-- GUI
------------------------------------
basic.registercom("CAPTION","S")
function basic_func.CAPTION(str)
	gui.caption(str)
	basic.lastcaption=str
end

basic.registercom("SETSCREEN","N")
function basic_func.SETSCREEN(mode)
	gui.setscreenmode(mode)
end

basic.registerfunc("GETSCREEN","")
function basic_func.GETSCREEN()
	if gui.getscreenmode()~=0 then return 1 else return 0 end
end

basic.registerfunc("GETCONFIG","S")
function basic_func.GETCONFIG(key)
	return gui.getconfig(key)
end


basic.registercom("DOEVENTS","")
function basic_func.DOEVENTS()
	gui.doevents()
end

basic.registercom("SLEEP","N")
function basic_func.SLEEP(mili)
	gui.sleep(mili)
end

basic.registercom("CLEARMESSAGE","")
function basic_func.CLEARMESSAGE()
	gui.clearmessage()
end

------------------------------------
-- GUI入力関連
------------------------------------
basic.registercom("SETMOUSE","NN")
function basic_func.SETMOUSE(x,y)
	gui.setmouse(x,y)
end

basic.registercom("GETMOUSE","RR")
function basic_func.GETMOUSE(xv,yv)
	local x,y=gui.getmouse()
	x=x or -1
	y=y or -1
	basic.vset(xv,x)
	basic.vset(yv,y)
end

basic.registercom("CLEARMOUSE","")
function basic_func.CLEARMOUSE()
	gui.clearbuffer()
end

basic.registercom("GETCLICK","R.")
function basic_func.GETCLICK(lv,rv,wv,ldv,rdv)
	local l,r,w,ld,rd=gui.getclick()
	if l then l=1 basic.skipmode=0 else l=0 end
	if r then r=1 else r=0 end
	if not w then w=0 end
	if ld then ld=1 else ld=0 end
	if rd then rd=1 else rd=0 end
	basic.vset(lv,l)
	if rv then basic.vset(rv,r) end
	if wv then basic.vset(wv,w) end
	if ldv then basic.vset(ldv,ld) end
	if rdv then basic.vset(rdv,rd) end
end

basic.registerfunc("GETKEY","S")
function basic_func.GETKEY(keystr)
	if gui.getkey(keystr) then return 1 else return 0 end
end

basic.registercom("GETPAD","NRRRRRRRRRRRRRRRRRR")
function basic_func.GETPAD(num,lxv,lyv,rxv,ryv,dxv,dyv,av,bv,xv,yv,startv,backv,l1v,r1v,l2v,r2v,l3v,r3v)
	local lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(num)
	if not lx then
		basic.vset(lxv,"#NODATA")
	else
		basic.vset(lxv,lx)
		basic.vset(lyv,ly)
		basic.vset(rxv,rx)
		basic.vset(ryv,ry)
		basic.vset(dxv,dx)
		basic.vset(dyv,dy)
		if start then basic.vset(startv,1) else basic.vset(startv,0) end
		if back then basic.vset(backv,1) else basic.vset(backv,0) end
		if a then basic.vset(av,1) else basic.vset(av,0) end
		if b then basic.vset(bv,1) else basic.vset(bv,0) end
		if x then basic.vset(xv,1) else basic.vset(xv,0) end
		if y then basic.vset(yv,1) else basic.vset(yv,0) end
		if l1 then basic.vset(l1v,1) else basic.vset(l1v,0) end
		if r1 then basic.vset(r1v,1) else basic.vset(r1v,0) end
		basic.vset(l2v,l2)
		basic.vset(r2v,r2)
		if l3 then basic.vset(l3v,1) else basic.vset(l3v,0) end
		if r3 then basic.vset(r3v,1) else basic.vset(r3v,0) end

	end
end


basic.registercom("INPUT","RSS")
function basic_func.INPUT(retv,text,caption)
	local ret=gui.input(text,caption)
	if ret==nil then ret="" end
	basic.vset(retv,ret)
end

basic.registercom("OKBOX","SS")
function basic_func.OKBOX(text,caption)
	gui.okbox(text,caption)
end

basic.registercom("YESNOBOX","RSS")
function basic_func.YESNOBOX(retv,text,caption)
	local ret=gui.yesnobox(text,caption)
	if ret then
		basic.vset(retv,1)
	else
		basic.vset(retv,0)
	end
end

------------------------------------
-- タイマ／時間関係
------------------------------------
local guitimer=0
basic.registercom("RESETTIMER","")
function basic_func.RESETTIMER()
	guitimer=gui.gettimer()
end

basic.registerfunc("GETTIMER","")
function basic_func.GETTIMER()
	return (gui.gettimer()-guitimer)%100000000 -- １０００００秒も待つことはないでしょ、たぶん。
	--４９日くらい放置されているWindowsではタイマが一周する瞬間に引き算の値が負になることがある。
	--剰余演算は負の無限大方向への丸め操作なので、正しく丸められるはず。
end

basic.registercom("WAITTIMER","N")
function basic_func.WAITTIMER(tm)
	movie.resume()
	local t
	while true do
		t=(gui.gettimer()-guitimer)%100000000
		if tm>t then
			gui.sleep(SLEEP_TIME)
			movie.render()
		else
			return
		end
	end
end


basic.registercom("TIME","RRRRRR")
function basic_func.TIME(year,month,day,hour,min,sec)
	local tbl=os.date("*t")
	basic.vset(year,tbl.year)
	basic.vset(month,tbl.month)
	basic.vset(day,tbl.day)
	basic.vset(hour,tbl.hour)
	basic.vset(min,tbl.min)
	basic.vset(sec,tbl.sec)
end

--FILETIME,SAVETIMEはC++命令として定義されます。


-----------------------------------
-- コンソール
-----------------------------------
basic.registercom("BEEP","*")
function basic_func.BEEP(freq,mili)
	if not freq or not tonumber(freq) then freq=nil end
	if not mili or not tonumber(mili) then mili=nil end
	console.beep(freq,mili)
end

basic.registercom("COPEN","")
function basic_func.COPEN()
	console.open()
end

basic.registercom("CCLOSE","")
function basic_func.CCLOSE()
	console.close()
end

basic.registercom("CCAPTION","S")
function basic_func.CCAPTION(str)
	console.caption(str)
end

basic.registercom("CPRINT","*")
function basic_func.CPRINT(...)
	local tbl={...}
	local str=table.concat(tbl)
	console.print (str)
end

basic.registercom("CWRITE","*")
function basic_func.CWRITE(...)
	local tbl={...}
	local str=table.concat(tbl)
	console.write (str)
end

basic.registerfunc("CREAD","")
function basic_func.CREAD()
	return console.readline()
end

basic.registercom("CLOCATE","NN")
function basic_func.CLOCATE(x,y)
	console.locate(x,y)
end

basic.registercom("CGETSIZE","RR")
function basic_func.CGETSIZE(wv,hv)
	local w,h=console.getsize()
	basic.vset(wv,w)
	basic.vset(hv,h)
end

basic.registercom("CSETSIZE","NN")
function basic_func.CSETSIZE(w,h)
	console.setsize(w,h)
end

basic.registercom("CGETCURSOR","RR")
function basic_func.CGETCURSOR(xv,yv)
	local x,y=console.getcursor()
	basic.vset(xv,x)
	basic.vset(yv,y)
end

basic.registercom("CSETTEXT","SN.")
function basic_func.CSETTEXT(...)
	local tbl={...}
	local str,x,y,cr,cg,cb,br,bg,bb,ci,bi
	str=tbl[1]
	x=tbl[2]
	y=tbl[3]
	cr=tbl[4] or 1
	cg=tbl[5] or 1
	cb=tbl[6] or 1
	br=tbl[7] or 0
	bg=tbl[8] or 0
	bb=tbl[9] or 0
	ci=tbl[10] or 0
	bi=tbl[11] or 0
	console.settext(str,x,y,cr,cg,cb,br,bg,bb,ci,bi)
end

basic.registercom("CCLEAR","")
function basic_func.CCLEAR()
	console.clear()
end

basic.registerfunc("CINKEY","")
function basic_func.CINKEY()
	return console.inkey()
end

basic.registercom("CCOLOR","N.")
function basic_func.CCOLOR(...)
	local tbl={...}
	local cr,cg,cb,br,bg,bb,ci,bi
	cr=tbl[1] or 1
	cg=tbl[2] or 1
	cb=tbl[3] or 1
	br=tbl[4] or 0
	bg=tbl[5] or 0
	bb=tbl[6] or 0
	ci=tbl[7] or 0
	bi=tbl[8] or 0
	return console.color(cr,cg,cb,br,bg,bb,ci,bi)
end

basic.registercom("SYSTEM","S")
function basic_func.SYSTEM(str)
	os.execute(str)
end

------------------------------------
-- 描画モード
------------------------------------

basic.registercom("GBEGIN","")
function basic_func.GBEGIN()
	draw.beginscene()
end

basic.registercom("GEND","")
function basic_func.GEND()
	draw.endscene()
end

basic.registercom("GBLEND","N")
function basic_func.GBLEND(mode)
	draw.blend(mode)
end


basic.registercom("GGETSIZE","RR")
function basic_func.GGETSIZE(wv,hv)
	local w,h=gui.getsize()
	basic.vset(wv,w)
	basic.vset(hv,h)
end


------------------------------------
-- テクスチャ処理
------------------------------------

-- 文字の書き込み命令。一文字のみ。
function FONT_PUT_CODE(dest,f,code,x,y,opt)
	local st=opt.fp.style
	if st=="normal" or st==nil or st=="" then
		f:put(dest,code,x,y,opt.fp.color)
	elseif st=="shadow" then
		f:put(dest,code,x+opt.fp.shadowx,y+opt.fp.shadowy,opt.fp.shadowcolor)
		f:put(dest,code,x,y,opt.fp.color)
	elseif st=="outline" then
		f:put(dest,code,x,y,opt.fp.outlinecolor)
		f:put(dest,code,x+1,y,opt.fp.outlinecolor)
		f:put(dest,code,x+2,y,opt.fp.outlinecolor)
		f:put(dest,code,x,y+1,opt.fp.outlinecolor)
		f:put(dest,code,x+1,y+1,opt.fp.outlinecolor)
		f:put(dest,code,x+2,y+1,opt.fp.outlinecolor)
		f:put(dest,code,x,y+2,opt.fp.outlinecolor)
		f:put(dest,code,x+1,y+2,opt.fp.outlinecolor)
		f:put(dest,code,x+2,y+2,opt.fp.outlinecolor)
		f:put(dest,code,x+1,y+1,opt.fp.color)
	elseif st=="fancy" then
		f:put(dest,code,x,y,opt.fp.outlinecolor)
		f:put(dest,code,x+1,y,opt.fp.outlinecolor)
		f:put(dest,code,x+2,y,opt.fp.outlinecolor)
		f:put(dest,code,x,y+1,opt.fp.outlinecolor)
		f:put(dest,code,x+1,y+1,opt.fp.outlinecolor)
		f:put(dest,code,x+2,y+1,opt.fp.outlinecolor)
		f:put(dest,code,x,y+2,opt.fp.outlinecolor)
		f:put(dest,code,x+1,y+2,opt.fp.outlinecolor)
		f:put(dest,code,x+2,y+2,opt.fp.outlinecolor)
		f:putgradation(dest,code,x+1,y+1,opt.fp.color1,opt.fp.color2,opt.fp.fx,opt.fp.fy)
	else
		error("フォント描画命令のパラメータが間違っています。")
	end
end


basic.registercom("TDELETE","S")
function basic_func.TDELETE(name)
	if basic.texture[name] then basic.texture[name]:delete() end
end

basic.registercom("TCREATE","SNN")
function basic_func.TCREATE(name,w,h)
	basic.texture[name]=texture.create(w,h)
end


basic.registercom("TLOAD","SS")
function basic_func.TLOAD(name,filename)
	--テクスチャロードは必ずここを通すこと。空白スプライトやファイルログへの登録を兼ねているから。
	if basic.texture[name] then basic.texture[name]:delete() end
	if filename:byte(1)==42 then
		--*(アスタリスク) 塗り潰しテクスチャ
		if filename:byte(2)==35 then
			local c=basic.htmlcolor_to_number(filename:sub(2,-1))
			local w,h=gui.getsize()
			basic.texture[name]=texture.create(w,h)
			basic.texture[name]:fill(c)
			return
		elseif filename:sub(2,2):lower()~="g" then
			local w,h,c=string.split(filename:sub(2,-1),",")
			basic.texture[name]=texture.create(w,h)
			basic.texture[name]:fill(basic.htmlcolor_to_number(c))
			return
		else
			local w,h,c1,c2,fx,fy
			if filename:byte(3)~=35 then
				w,h,c1,c2,fx,fy=string.split(filename:sub(3,-1),",")
			else
				w,h=gui.getsize()
				c1,c2,fx,fy=string.split(filename:sub(3,-1),",")
			end
			if tonumber(fx)~=0 then fx=true else fx=false end
			if tonumber(fy)~=0 then fy=true else fy=false end
			local bmp=bitmap.create(w,h)
			bmp:gradation(basic.htmlcolor_to_number(c1),basic.htmlcolor_to_number(c2),fx,fy)
			basic.texture[name]=texture.frombitmap(bmp)
			bmp:delete()
			return
		end
	end
	if filename:byte(1)==62 then
		-->(大なり記号) 塗り潰しバー
		if filename:sub(2,2):lower()~="g" then
			local chr=filename:sub(2,2):lower()
			if chr~="l" and chr~="r" then
				error("塗り潰しバー指定が間違っています。")
			end
			local w,h,p,num,c,c2=string.split(filename:sub(3,-1),",")
			basic.texture[name]=texture.create(w,h)
			basic.texture[name]:fill(basic.htmlcolor_to_number(c2))
			if chr=="l" then
				basic.texture[name]:fillrect(0,0,w*p/(num-1),h,basic.htmlcolor_to_number(c))
			elseif chr=="r" then
				basic.texture[name]:fillrect(w*(num-1-p)/(num-1),0,w,h,basic.htmlcolor_to_number(c))
			end
			return
		else
			local chr=filename:sub(3,3):lower()
			if chr~="l" and chr~="r" then
				error("塗り潰しバー指定が間違っています。")
			end
			local w,h,p,num,c11,c12,c21,c22,fx,fy=string.split(filename:sub(4,-1),",")
			local bmp=bitmap.create(w,h)
			if tonumber(fx)~=0 then fx=true else fx=false end
			if tonumber(fy)~=0 then fy=true else fy=false end
			bmp:gradation(basic.htmlcolor_to_number(c21),basic.htmlcolor_to_number(c22),fx,fy)
			if chr=="l" then
				bmp:gradationrect(0,0,w*p/(num-1),h,basic.htmlcolor_to_number(c11),basic.htmlcolor_to_number(c12),fx,fy)
			elseif chr=="r" then
				bmp:gradationrect(w*(num-1-p)/(num-1),0,w,h,basic.htmlcolor_to_number(c11),basic.htmlcolor_to_number(c12),fx,fy)
			end
			basic.texture[name]=texture.frombitmap(bmp)
			bmp:delete()
			return
		end
	end
	if filename:byte(1)==0x3f then
		--?ではじまるのは 文字列テクスチャ
		local str,fontname,tbl
		local src=filename:sub(2,-1)
		str,fontname,tbl=src:match("^(.*),(.-),%((.*)%)$")
		if str==nil or fontname==nil then
			str,fontname=src:match("^(.*),(.-)$")
			if str==nil or fontname==nil then
				error("文字列テクスチャ指定が間違っています。")
			end
			tbl=nil
		end
		--文字列の長さからテクスチャサイズを逆算して作成
		if str=="" then
			local tex=texture.create(1,1)
			tex:fill(0x00000000)
			basic.texture[name]=tex
			return
		end
		local code=encoding.utf8_to_utf16(str)
		local opt
		if tbl then
			opt=basic.decodetable(tbl)
		else
			opt={}
		end
		opt.x=opt.x or 0
		opt.y=opt.y or 0
		--フォント設定
		if not fontname then error("テキスト表示命令にフォントが設定されていません") end
		opt.fp=basic.fontparam[fontname]
		if opt.fp==nil then error("フォント"..fontname.."が登録されていません。") end
		opt.fw=opt.fp.width
		opt.fh=opt.fp.height
		opt.px=opt.px or opt.fw -- 横送り幅
		opt.py=opt.py or opt.fh -- 縦送り幅
		opt.fp.color = opt.fp.color or 0xFFFFFFFF
		opt.fp.shadowcolor = opt.fp.shadowcolor or 0xFF000000
		opt.fp.shadowx = opt.fp.shadowx or 1
		opt.fp.shadowy = opt.fp.shadowy or 1
		opt.fp.outlinecolor = opt.fp.outlinecolor or 0xFF000000
		opt.fp.color1 = opt.fp.color1 or 0xFFFFFFFF
		opt.fp.color2 = opt.fp.color2 or 0xFFFFFF88
		local fw,fh=opt.fw,opt.fh
		if opt.fp.x then fw=fw+opt.fp.x end
		if opt.fp.y then fh=fh+opt.fp.y end
		if opt.fp.style=="outline" or opt.fp.style=="fancy" then
			fw=fw+2	fh=fh+2
		end
		local tex
		tex=texture.create(#code*fw+opt.fp.shadowx,fh+opt.fp.shadowx)
		--文字を印字する
		local fnt=font.create(opt.fp)
		local textx=opt.x
		for i,v in ipairs(code) do
			FONT_PUT_CODE(tex,fnt,v,textx,opt.y,opt)
			textx=textx+opt.px
		end
		basic.texture[name]=tex
		return
	end
	basic.texture[name]=texture.load(filename)
	filename=filename:upper()
	basic.filelog[filename]=true
end
basic.registercom("FINSERT","S")
function basic_func.FINSERT(name)
	name=name:upper()
	basic.filelog[name]=true
end
basic.registerfunc("FCHK","S")
function basic_func.FCHK(name)
	name=name:upper()
	if basic.filelog[name] then
		return 1
	else
		return 0
	end
end
basic.registercom("TDRAW","SNNN")
function basic_func.TDRAW(name,x,y,a)
	local t=basic.texture[name]
	if t then
		t:draw(x,y,a)
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end
basic.registerfunc("TISPLAYING","S")
function basic_func.TISPLAYING(name)
	local t=basic.texture[name]
	if t then
		if t:isplaying() then return 1 else return 0 end
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end
basic.registercom("TDRAWLT","SNNNNNN")
function basic_func.TDRAWLT(name,cx,cy,xs,ys,rot,a)
	local t=basic.texture[name]
	if t then
		t:drawlt(cx,cy,xs,ys,rot,a)
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("TFILL","SS")
function basic_func.TFILL(name,col)
	local t=basic.texture[name]
	col=basic.htmlcolor_to_number(col)
	if t then
		t:fill(col)
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("TFRECT","SNNNNS")
function basic_func.TFRECT(name,lx,ly,rx,ry,col)
	local t=basic.texture[name]
	col=basic.htmlcolor_to_number(col)
	if t then
		t:fillrect(lx,ly,rx,ry,col)
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("TGETSIZE","SRR")
function basic_func.TGETSIZE(name,wv,hv)
	local t=basic.texture[name]
	if t then
		local w,h=t:getsize()
		basic.vset(wv,w)
		basic.vset(hv,h)
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("TSAVE","SS")
function basic_func.TSAVE(name,filename)
	local t=basic.texture[name]
	if t then
		t:save(filename)
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("TBEGIN","S")
function basic_func.TBEGIN(name)
	local t=basic.texture[name]
	if t then
		t:beginscene()
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("TEND","")
function basic_func.TEND()
	local t=basic.texture[name]
	if t then
		t:endscene()
	else
		error("存在しないテクスチャ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("TFROMB","SS")
function basic_func.TFROMB(tname,bname)
	local b=basic.bitmap[bname]
	if b then
		basic.texture[tname]=texture.frombitmap(b)
	else
		error("存在しないビットマップ\""..bname.."\"を処理しようとしました。")
	end
end

------------------------------------
-- ビットマップ処理
------------------------------------
basic.registercom("BCREATE","SNN")
function basic_func.BCREATE(name,w,h)
	basic.bitmap[name]=bitmap.create(w,h)
end

basic.registercom("BFROMT","SS")
function basic_func.BFROMT(bname,tname)
	local t=basic.texture[tname]
	if t then
		basic.bitmap[bname]=bitmap.fromtexture(t)
	else
		error("存在しないテクスチャ\""..tname.."\"を処理しようとしました。")
	end
end

basic.registercom("BLOAD","SS")
function basic_func.BLOAD(name,filename)
	--BLOADもファイルログへの登録対象
	filename=filename:upper()
	basic.filelog[filename]=true
	basic.bitmap[name]=bitmap.load(filename)
end

basic.registercom("BDELETE","S")
function basic_func.BDELETE(name)
	local b=basic.bitmap[name]
	if b then
		b:delete()
	else
		--deleteは、ない場合は素通りする。
	end
end

basic.registercom("BSAVE","SS*")
function basic_func.BSAVE(name,filename,quality)
	local b=basic.bitmap[name]
	if b then
		filename=filename:lower()
		if filename:match("png") then
			b:save(filename)
		elseif filename:match("jpeg") or filename:match("jpg") then
			quality=quality or 95
			b:savejpeg(filename,quality)
		else
			error("対応していないファイル形式\""..filename.."\"でビットマップ\""..name.."\"を保存しようとしました。")
		end
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BFILL","SS")
function basic_func.BFILL(name,col)
	local b=basic.bitmap[name]
	col=basic.htmlcolor_to_number(col)
	if b then
		b:fill(col)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BFRECT","SNNNNS")
function basic_func.BFRECT(name,lx,ly,rx,ry,col)
	local b=basic.bitmap[name]
	col=basic.htmlcolor_to_number(col)
	if b then
		b:fillrect(lx,ly,rx,ry,col)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BREVERSE","SNN")
function basic_func.BREVERSE(name,xflag,yflag)
	local b=basic.bitmap[name]
	if b then
		b:reverse(xflag,yflag)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BRESIZE","SNN")
function basic_func.BRESIZE(name,w,h)
	local b=basic.bitmap[name]
	if b then
		b:resize(w,h)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BTRIM","SNNNN")
function basic_func.BTRIM(name,lx,ly,rx,ry)
	local b=basic.bitmap[name]
	if b then
		b:trim(lx,ly,rx,ry)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BJOINX","SS")
function basic_func.BJOINX(lname,rname)
	local lb=basic.bitmap[lname]
	local rb=basic.bitmap[rname]
	if not lb then error("存在しないビットマップ\""..lname.."\"を処理しようとしました。") end
	if not rb then error("存在しないビットマップ\""..rname.."\"を処理しようとしました。") end
	lb:joinx(rb)
end

basic.registercom("BJOINY","SS")
function basic_func.BJOINY(uname,dname)
	local ub=basic.bitmap[uname]
	local db=basic.bitmap[dname]
	if not ub then error("存在しないビットマップ\""..uname.."\"を処理しようとしました。") end
	if not db then error("存在しないビットマップ\""..dname.."\"を処理しようとしました。") end
	ub:joinx(db)
end

basic.registercom("BGETSIZE","SRR")
function basic_func.BGETSIZE(name,wv,hv)
	local b=basic.bitmap[name]
	if b then
		local w,h=b:getsize()
		basic.vset(wv,w)
		basic.vset(hv,h)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BDUP","SS")
function basic_func.BDUP(destname,srcname)
	local sb=basic.bitmap[srcname]
	if not sb then error("存在しないビットマップ\""..srcname.."\"を処理しようとしました。") end
	basic.texture[destname]=sb:dup()
end

basic.registercom("BGRADATION","SSSNN")
function basic_func.BGRADATION(name,col1,col2,xflag,yflag)
	local b=basic.bitmap[name]
	col1=basic.htmlcolor_to_number(col1)
	col2=basic.htmlcolor_to_number(col2)
	if b then
		b:gradation(col1,col2,xflag,yflag)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BNEGA","S")
function basic_func.BNEGA(name)
	local b=basic.bitmap[name]
	if b then
		b:nega()
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BMONOTONE","SS")
function basic_func.BMONOTONE(name,col)
	local b=basic.bitmap[name]
	col=basic.htmlcolor_to_number(col)
	if b then
		b:monotone(col)
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BBEGIN","S")
function basic_func.BBEGIN(name)
	local b=basic.bitmap[name]
	if b then
		b:beginscene()
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("BEND","S")
function basic_func.BEND(name)
	local b=basic.bitmap[name]
	if b then
		b:endscene()
	else
		error("存在しないビットマップ\""..name.."\"を処理しようとしました。")
	end
end

------------------------------------
-- ムービー処理
--（テクスチャムービーはテクスチャの読み込み部分に組み込まれています。）
------------------------------------
basic.registercom("MOVIE","S*")
function basic_func.MOVIE(name,clickskip,volume)
	--MOVIEもファイルログへの登録対象
	name=name:upper()
	basic.filelog[name]=true
	clickskip=tonumber(clickskip) or 1
	volume=tonumber(volume) or basic.data.bgmvol or 0
	if basic.skipmode==1 and clickskip~=0 then return end
	movie.play(name,clickskip,volume)
end

basic.registercom("MRESET","")
function basic_func.MRESET()
	movie.reset()
end

------------------------------------
-- トランジション処理
------------------------------------
basic.registercom("TRANSITION","SSNS*")
function basic_func.TRANSITION(from_tex,to_tex,rate,typestr,opt0)
	local from=basic.texture[from_tex]
	local to=basic.texture[to_tex]
	if not from then error("存在しないテクスチャ\""..from_tex.."\"を処理しようとしました。") end
	if not to then error("存在しないテクスチャ\""..to_tex.."\"を処理しようとしました。") end
	--シナリオ命令での瞬時表示の実装は""もしくは"#C"もしくは"#CUT"で行うが、
	--これはトランジション関数には来ない。
	if typestr=="#F" or typestr=="#FADE" then
		transition.fade(from,to,rate)
	elseif typestr=="#RU" or typestr=="#ROLLUP" then
		transition.rollup(from,to,rate)
	elseif typestr=="#RD" or typestr=="#ROLLDOWN" then
		transition.rolldown(from,to,rate)
	elseif typestr=="#RL" or typestr=="#ROLLLEFT" then
		transition.rollleft(from,to,rate)
	elseif typestr=="#RR" or typestr=="#ROLLRIGHT" then
		transition.rollright(from,to,rate)
	elseif typestr=="#SU" or typestr=="#SLIDEUP" then
		transition.slideup(from,to,rate)
	elseif typestr=="#SD" or typestr=="#SLIDEDOWN" then
		transition.slidedown(from,to,rate)
	elseif typestr=="#SL" or typestr=="#SLIDELEFT" then
		transition.slideleft(from,to,rate)
	elseif typestr=="#SR" or typestr=="#SLIDERIGHT" then
		transition.slideright(from,to,rate)
	elseif typestr=="#U" or typestr=="#UNIVERSAL" then
		local rulebmp
		if type(opt0)~="string" or not basic.bitmap[opt0] then
			error("TRANSITION命令のユニバーサルエフェクトの第5引数はルール画像のビットマップオブジェクト名です\r\n（注：ファイル名ではありません、テクスチャ名でもありません）。"..typestr)
		else
			transition.universal(from,to,rate,basic.bitmap[opt0])
		end
	else
		error("TRANSITION命令に与えたタイプ指定が不正です。:"..typestr)
	end
end

------------------------------------
-- BGM/SE/VOICE/BGV処理
------------------------------------
basic.registercom("BGMPLAY","S")
function basic_func.BGMPLAY(filename)
	if filename=="" then
		basic.sound["BGM0"]:fadeout(basic.data.bgmfadeout)
		basic.sound["BGM1"]:fadeout(basic.data.bgmfadeout)
		basic.bgmname=""
		return
	end
	basic.bgmname=filename
	local tbl={name=filename,loop=true,volume=basic.data.bgmvol}
	if basic.sound["BGM0"]:isplaying() then
		basic.sound["BGM0"]:fadeout(basic.data.bgmfadeout)
		basic.sound["BGM1"]:play(tbl)
	elseif basic.sound["BGM1"]:isplaying() then
		basic.sound["BGM1"]:fadeout(basic.data.bgmfadeout)
		basic.sound["BGM0"]:play(tbl)
	else
		basic.sound["BGM0"]:play(tbl)
	end
end
basic.registercom("BGMPLAYONCE","S")
function basic_func.BGMPLAYONCE(filename)
	basic.bgmname=""
	if filename=="" then
		basic.sound["BGM0"]:fadeout(basic.data.bgmfadeout)
		basic.sound["BGM1"]:fadeout(basic.data.bgmfadeout)
		return
	end
	local tbl={name=filename,loop=false,volume=basic.data.bgmvol}
	if basic.sound["BGM0"]:isplaying() then
		basic.sound["BGM0"]:fadeout(basic.data.bgmfadeout)
		basic.sound["BGM1"]:play(tbl)
	elseif basic.sound["BGM1"]:isplaying() then
		basic.sound["BGM1"]:fadeout(basic.data.bgmfadeout)
		basic.sound["BGM0"]:play(tbl)
	else
		basic.sound["BGM0"]:play(tbl)
	end
end
basic.registercom("BGMSTOP","")
function basic_func.BGMSTOP()
	basic.sound["BGM0"]:fadeout(basic.data.bgmfadeout)
	basic.sound["BGM1"]:fadeout(basic.data.bgmfadeout)
	basic.bgmname=""
end
basic.registercom("BGMFADEOUT","N")
function basic_func.BGMFADEOUT(mili)
	basic.data.bgmfadeout=mili
end
basic.registercom("BGMVOLUME","N")
function basic_func.BGMVOLUME(vol)
	basic.data.bgmvol=vol
	basic.sound["BGM0"]:volume(vol)
	basic.sound["BGM1"]:volume(vol)
end
basic.registerfunc("GETBGMVOLUME","")
function basic_func.GETBGMVOLUME()
	return basic.data.bgmvol
end
basic.registercom("SEPLAY","NS")
function basic_func.SEPLAY(ch,filename)
	local tbl={name=filename,loop=false,volume=basic.data.sevol}
	basic.sound["SE"..ch]:play(tbl)
end
basic.registercom("SELOOP","NS")
function basic_func.SELOOP(ch,filename)
	local tbl={name=filename,loop=true,volume=basic.data.sevol}
	basic.sound["SE"..ch]:play(tbl)
	basic.seloopname[ch]=filename
end
basic.registercom("SESTOP","N")
function basic_func.SESTOP(ch,filename)
	basic.sound["SE"..ch]:fadeout(basic.data.sefadeout)
	basic.seloopname[ch]=nil
end
basic.registercom("SESTOPALL","")
function basic_func.SESTOPALL(ch,filename)
	for ch=0,15 do
		basic.seloopname[ch]=nil
		basic.sound["SE"..ch]:fadeout(basic.data.sefadeout)
	end
end

basic.registercom("SEFADEOUT","N")
function basic_func.SEFADEOUT(mili)
	basic.data.sefadeout=mili
end
basic.registercom("SEVOLUME","N")
function basic_func.SEVOLUME(vol)
	basic.data.sevol=vol
	for i=0,15 do
		basic.sound["SE"..i]:volume(vol)
	end
end
basic.registerfunc("GETSEVOLUME","")
function basic_func.GETSEVOLUME()
	return basic.data.sevol
end
basic.registercom("SECHVOLUME","NN")
function basic_func.SECHVOLUME(ch,vol)
	basic.sound["SE"..ch]:volume(vol)
end
basic.registercom("VOICEPLAY","S*")
function basic_func.VOICEPLAY(filename,num)
	local vch
	if filename=="" then
		basic.sound["VOICE"]:stop()
		return
	end

--	if not archive.seek(filename) then return end --見つからなくても素通りさせたければコメントアウト

	local tbl={name=filename,loop=false,volume=basic.data.voicevol}
	if num then
		tbl.speed=2
		basic.sound["VOICE"]:play(tbl)
	else
		basic.sound["VOICE"]:play(tbl)
	end
	basic.bgvstopflag=true
	for ch=0,15 do
		basic.sound["BGV"..ch]:pause(vol)
	end
end

basic.registercom("VOICEWAIT","")
function basic_func.VOICEWAIT()
	while true do
		basic.sprite_animation_check()
		basic.SPDRAW_sub()
		gui.doevents()
		if not basic.sound["VOICE"]:isplaying() then
			return
		end
		gui.sleep(SLEEP_TIME)
	end
end
basic.registercom("VOICEVOLUME","N")
function basic_func.VOICEVOLUME(vol)
	basic.data.voicevol=vol
	basic.sound["VOICE"]:volume(vol)
end
basic.registerfunc("GETVOICEVOLUME","")
function basic_func.GETVOICEVOLUME()
	return basic.data.sevol
end
basic.registercom("BGVPLAY","NS")
function basic_func.BGVPLAY(ch,filename)
	if filename=="" then
		basic.sound["BGV"..ch]:fadeout(basic.data.bgvfadeout)
		basic.bgvname[ch]=nil
		return
	end
	local tbl={name=filename,loop=true,volume=basic.data.bgvvol}
	basic.sound["BGV"..ch]:play(tbl)
	basic.bgvname[ch]=filename
end
basic.registercom("BGVFADEOUT","N")
function basic_func.BGVFADEOUT(mili)
	basic.data.bgvfadeout=mili
end
basic.registercom("BGVVOLUME","N")
function basic_func.BGVVOLUME(vol)
	basic.data.bgvvol=vol
	for ch=0,15 do
		basic.sound["BGV"..ch]:volume(vol)
	end
end
basic.registerfunc("GETBGVVOLUME","")
function basic_func.GETBGVVOLUME()
	return basic.data.bgvvol
end

------------------------------------
--低水準　サウンド処理
------------------------------------
--Luaで実装されているサウンドクラスを直接扱う命令です。
--BGM BGV VOICE SE のチャンネル名を使えば、それらを細かく調整できます。
--ただし、こちらの実行結果はセーブで保存されません。ご注意ください。

basic.registercom("SOUND","S")
function basic_func.SOUND(name)
	basic.sound[name]=sound.create()
end

basic.registercom("SDELETE","S")
function basic_func.SDELETE(name)
	local s=basic.sound[name]
	if s then
		s:endscene()
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("SPLAY","ST")
function basic_func.SPLAY(name,param)
	local s=basic.sound[name]
	if s then
		local opt=basic.decodetable(param)
		opt.loop=basic.number_to_boolean(opt.loop)
		if not opt.name then error("SPLAYの指定にはname要素が必要です。") end
		s:play(opt)
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("SSTOP","S")
function basic_func.SSTOP(name)
	local s=basic.sound[name]
	if s then
		s:close()
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("SVOLUME","SN")
function basic_func.SVOLUME(name,vol)
	local s=basic.sound[name]
	if s then
		s:volume(vol)
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("SPAN","SN")
function basic_func.SPAN(name,pan)
	local s=basic.sound[name]
	if s then
		s:pan(pan)
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("SFADEOUT","SN")
function basic_func.SFADEOUT(name,time)
	local s=basic.sound[name]
	if s then
		s:fadeout(time)
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registerfunc("SISPLAYING","S")
function basic_func.SISPLAYING(name)
	local s=basic.sound[name]
	if s then
		if s:isplaying() then return 1 else return 0 end
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("SPAUSE","")
function basic_func.SPAUSE()
	local s=basic.sound[name]
	if s then
		s:pause()
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end

basic.registercom("SRESUME","")
function basic_func.SRESUME()
	local s=basic.sound[name]
	if s then
		s:resume()
	else
		error("存在しないサウンド\""..name.."\"を処理しようとしました。")
	end
end



------------------------------------
-- スプライト／スプライトセット処理
------------------------------------
function basic.spnamesplit(str)
	--スプライト名からスプライトセット名とスプライト名を分離
	if str:find(":") then
		return string.split(str,":")
	else
		return "",str
	end
end

function basic.spdelete_sub(setname,spname)
	--テクスチャの消去
	local r=basic.spriteset[setname][spname]
	local name
	if setname~="" then name=setname..":"..spname else name=spname end
	if r.filtername then
		local f=basic_filter["delete_"..r.filtername]
		if not f then
			error("フィルタ"..r.filtername.."が正しく実装されていません。")
		end
		f(r.filterhandle,r.filteropt)
		r.filtername=nil
		r.filterhandle=nil
		r.filteropt=nil
	else
		for i=0,r.cellnum-1 do
			basic_func.TDELETE(name..":"..i)
		end
	end
	--スプライトデータの消去
	basic.spriteset[setname][spname]=nil
	basic.spritesetsort(setname)
end
function basic.SPDRAW_sub(target)
	--画面描画
	local blend=0
	local filterflag=false
	for k,v in pairs(basic.spriteset) do
		for k2,v2 in pairs(v) do
			if v2.filtername then filterflag=true end
		end
	end
	local outbmp,outtex
	if filterflag==false then
		if target==nil then
			draw.beginscene()
		else
			target:beginscene()
		end
	else
		local w,h=gui.getsize()
		outbmp=bitmap.create(w,h)
		outbmp:beginscene()
	end
	draw.blend(0)
	for i,v in ipairs(basic.draworder) do
		if basic.set_attr[v.name].visible==1 then
			for i2,v2 in ipairs(basic.draworderset[v.name]) do
				local r=basic.spriteset[v.name][v2.name]
				if r.visible==1 then
					if r.filtername then
						--フィルタ
						outbmp:endscene()
						local now=outbmp
						local f=basic_filter["draw_"..r.filtername]
						if not f then error("フィルタ"..r.filtername.."が正しく実装されていません。") end
						f(r.filterhandle,r.filteropt,now)
						local w,h=gui.getsize()
						outbmp=bitmap.create(w,h)
						if outtex then outtex:delete() end
						outtex=texture.frombitmap(now)
						now:delete()
						outbmp:beginscene()
						outtex:draw(0,0,255)
					else
						--普通のスプライトの表示
						local texname
						if v.name~="" then texname=v.name..":"..v2.name else texname=v2.name end
						texname=texname..":"..r.cell
						if r.blend~=blend then blend=r.blend draw.blend(blend) end
						if r.x then
							basic.texture[texname]:draw(r.x,r.y,r.a)
						elseif r.cx then
							if r.bezmat then
								basic.texture[texname]:drawbezierwarp(r.cx,r.cy,r.xs,r.ys,r.rot,r.bezmat,r.a,DIVISION)
							else
								basic.texture[texname]:drawlt(r.cx,r.cy,r.xs,r.ys,r.rot,r.a)
							end
						else
							error("スプライトの内部エラーです。")
						end
					end
				end
			end
		end
	end
	if filterflag==false then
		if target==nil then
			draw.endscene()
		else
			target:endscene()
		end
	else
		outbmp:endscene()
		if outtex then outtex:delete() end
		outtex=texture.frombitmap(outbmp)
		if target==nil then
			draw.beginscene()
		else
			target:beginscene()
		end
		outtex:draw(0,0,255)
		if target==nil then
			draw.endscene()
		else
			target:endscene()
		end
	end
	if outtex then outtex:delete() end
	if outbmp then outbmp:delete() end
end

function basic.sprite_animation_check ()
	movie.render()
	if callback.basic_animation then
		callback.basic_animation()
	end
	if not basic.sound["VOICE"]:isplaying() and basic.bgvstopflag then
		for ch=0,15 do
			if basic.bgvname[ch] then
				basic.sound["BGV"..ch]:resume(vol)
			end
		end
		basic.bgvstopflag=false
	end
	--セルアニメーション
	local dellist={}
	for k,v in pairs(basic.spriteset) do
		for k2,v2 in pairs(v) do
			if v2.delete==1 then
				local texname
				if k~="" then
					texname=k..":"..k2..":"..v2.cell
				else
					texname=k2..":"..v2.cell
				end
				if not basic.texture[texname]:isplaying() then
					dellist[#dellist+1]={k,k2}
				end
			end
			if v2.filtername==nil and v2.animtime~=0 then
				local t=gui.gettimer()
				if t>v2.count+v2.animtime then
					v2.count=t
					local tp=v2.animtype
					if tp==nil or tp=="" or tp=="normal" then
						v2.cell=v2.cell+1
						if v2.cell>=v2.cellnum then v2.cell=0 end
					elseif tp=="round" then
						v2.cell=v2.cell+v2.animvec
						if v2.cell+v2.animvec>=v2.cellnum or v2.cell+v2.animvec<0 then
							v2.animvec=-v2.animvec
						end
					elseif tp=="stop" then
						v2.cell=v2.cell+1
						if v2.cell>=v2.cellnum then v2.cell=v2.cellnum-1 end
					elseif tp=="delete" then
						v2.cell=v2.cell+1
						if v2.cell>=v2.cellnum then dellist[#dellist+1]={k,k2} end
					elseif tp=="lua" then
						basic_func[v2.animfunc] (k,k2,v2)
					end
				end
			end
		end
	end
	for i,v in ipairs(dellist) do
		basic.spdelete_sub(v[1],v[2])
	end
end

function basic.drawordercomp(a,b)
	local az=a.z
	local bz=b.z
	if az>bz then return true end
	if az<bz then return false end
	if a.name>b.name then return true end
	return false
end

function basic.spritesetsort(setname)
	basic.draworderset[setname]={}
	local index=1
	for k,v in pairs(basic.spriteset[setname]) do
		basic.draworderset[setname][index]={name=k,z=v.z}
		index=index+1
	end
	table.sort(basic.draworderset[setname],basic.drawordercomp)
end

function basic.spriteallsort()
	basic.draworder={}
	local index=1
	for k,v in pairs(basic.spriteset) do
		basic.draworder[index]={name=k,z=basic.set_attr[k].z}
		index=index+1
	end
	table.sort(basic.draworder,basic.drawordercomp)
end

function basic.createoffscreen()
	--オフスクリーンに現在の画面状態を書き込む。
	--自動でムービーを一時停止する。PRINTで再開されるが、
	--例えばエフェクトなどの他用途で使っている場合は終わったらmovie.resumeで戻すこと。
	movie.pause()
	if not basic.data.offscreenfrom then
		local w,h=gui.getsize()
		basic.data.offscreenfrom=texture.create(w,h)
		basic.data.offscreento=texture.create(w,h)
	end
	if not basic.data.offscreenflag then
		basic.SPDRAW_sub(basic.data.offscreenfrom)
		basic.data.offscreenflag=true
	end
end

function basic.SP_sub(setname,spname,opt)
	local name
	if setname~="" then
		name=setname..":"..spname
	else
		name=spname
	end
	local cellnum
	if not basic.spriteset[setname] then
		error("存在しないスプライトセット"..setname.."を指定しました。")
	end
	--データの初期化
	basic.spriteset[setname][spname]={}
	basic.spriteset[setname][spname].a=opt.a or 255
	basic.spriteset[setname][spname].z=opt.z or 0
	basic.spriteset[setname][spname].blend=opt.blend or 0
	basic.spriteset[setname][spname].visible=opt.visible or 1
	basic.spriteset[setname][spname].count=gui.gettimer()
	basic.spriteset[setname][spname].animvec=1
	if opt.x then
		basic.spriteset[setname][spname].x=opt.x
		basic.spriteset[setname][spname].y=opt.y or 0
	elseif opt.cx then
		basic.spriteset[setname][spname].cx=opt.cx
		basic.spriteset[setname][spname].cy=opt.cy or 0
		basic.spriteset[setname][spname].xs=opt.xs or 1
		basic.spriteset[setname][spname].ys=opt.ys or 1
		if opt.rot then basic.spriteset[setname][spname].rot=opt.rot else basic.spriteset[setname][spname].rot=0 end
	else
		basic.spriteset[setname][spname].x=0
		basic.spriteset[setname][spname].y=0
	end
	local parent=opt.parent or ""
	if parent~="" and parent:find(":")==nil then parent=":"..parent end
	basic.spriteset[setname][spname].parent=parent
	basic.spriteset[setname][spname].animtype=opt.animtype or ""
	basic.spriteset[setname][spname].animtime=opt.animtime or 0
	basic.spriteset[setname][spname].cell=0
	basic.spriteset[setname][spname].delete=opt.delete or 0
	--テクスチャのロード
	if opt.filter then
		opt.filter=opt.filter:upper()
		basic.spriteset[setname][spname].filtername=opt.filter
		basic.spriteset[setname][spname].filterhandle=basic.filter_handle
		basic.filter_handle=basic.filter_handle+1
		if basic.filter_handle>100000 then basic.filter_handle=0 end
		local f=basic_filter["init_"..opt.filter]
		if not f then
			error("フィルタ"..opt.filter.."が正しく実装されていません。")
		end
		f(basic.spriteset[setname][spname].filterhandle,opt)
		basic.spriteset[setname][spname].filteropt=opt
	elseif opt.sname then
		--画像分割タイプ
		if not opt.sx then
			error("スプライトの画像を分割する際はsxを指定する必要があります(syは省略すると1)")
		end
		local xx,yy
		xx=opt.sx or 1
		yy=opt.sy or 1
		local swd,sht
		cellnum=xx*yy
		local bmp=bitmap.load(opt.sname)
		if opt.effect=="nega" then bmp:nega() end
		if opt.effect=="monotone" then bmp:monotone(basic.htmlcolor_to_number(opt.color)) end

		swd,sht=bmp:getsize()
		swd=math.floor(swd/xx)
		sht=math.floor(sht/yy)
		basic.filelog[opt.sname:upper()]=true
		for j=1,yy do
			for i=1,xx do
				local nm=name..":"..tostring((i-1)+(j-1)*yy)
				if basic.texture[nm] then basic.texture[nm]:delete() end
				basic.texture[name..":"..tostring((i-1)+(j-1)*yy)]=texture.frombitmaprect(bmp,swd*(i-1),sht*(j-1),swd,sht)
			end
		end
	elseif type(opt.name)=="table" then
		--複数セルのテクスチャ
		cellnum=#(opt.name)
		local monocolor
		if opt.effect=="monotone" then monocolor=basic.htmlcolor_to_number(opt.color) end
		for i,v in ipairs(opt.name) do
			local texname=name..":"..i-1
			basic_func.TLOAD(texname,v)
			if opt.effect=="nega" then basic.texture[texname]:nega() end
			if opt.effect=="monotone" then basic.texture[texname]:monotone(monocolor) end
		end
	else
		cellnum=1
		local texname=name..":"..0
		basic_func.TLOAD(texname,opt.name)
		if opt.effect=="nega" then basic.texture[texname]:nega() end
		if opt.effect=="monotone" then basic.texture[texname]:monotone(basic.htmlcolor_to_number(opt.color)) end
	end
	basic.spriteset[setname][spname].cellnum=cellnum
	basic.spritesetsort(setname)
end

basic.registercom("SP","ST")
function basic_func.SP(name,param)
	basic.createoffscreen()
	local setname,spname=basic.spnamesplit(name)
	local opt=basic.decodetable(param)
	basic_func.SPDELETE(name)
	basic.SP_sub(setname,spname,opt)
	basic.spriteset[setname][spname].str=param
end

basic.registercom("BTNSTR","S")
function basic_func.BTNSTR(str)
	basic.BTNSTREXEC(str)
end

basic.registerfunc("GETSPCELL","S")
function basic_func.GETSPCELL(name)
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		error("存在しないスプライト"..name.."を指定しました。")
	end
	local r=basic.spriteset[setname][spname]
	return r.cell
end

function basic.getspritesize(name)
	local setname,spname=basic.spnamesplit(name)
	local name
	if setname~="" then
		name=setname..":"..spname
	else
		name=spname
	end
	return basic.texture[name..":0"]:getsize()
end

basic.registercom("GETSPINFO","SR")
function basic_func.GETSPINFO(name,vname)
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		error("存在しないスプライト"..name.."を指定しました。")
	end
	local r=basic.spriteset[setname][spname]
	basic.vset(vname..".A",r.a)
	basic.vset(vname..".Z",r.z)
	basic.vset(vname..".BLEND",r.blend)
	basic.vset(vname..".CELL",r.cell)
	basic.vset(vname..".CELLNUM",r.cellnum)
	local w,h=basic.texture[name..":0"]:getsize()
	basic.vset(vname..".W",w)
	basic.vset(vname..".H",h)

	if r.x then
		basic.vset(vname..".X",r.x)
		basic.vset(vname..".Y",r.y)
	end

	if r.cx then
		basic.vset(vname..".CX",r.cx)
		basic.vset(vname..".CY",r.cy)
		basic.vset(vname..".XS",r.xs)
		basic.vset(vname..".YS",r.ys)
		basic.vset(vname..".ROT",math.deg(r.rot))
	end

	if r.animtype then
		basic.vset(vname..".ANIMTYPE",r.animtype)
		basic.vset(vname..".ANIMTIME",r.animtime)
	end
end
basic.registercom("SPDELETE","S")
function basic_func.SPDELETE(name)
	basic.createoffscreen()
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return
	end
	basic.spdelete_sub(setname,spname)
end
basic.registercom("SPDELETES","S")
function basic_func.SPDELETES(header)
	basic.createoffscreen()
	local setname,spheader=basic.spnamesplit(header)
	local l=#spheader
	if not basic.spriteset[setname] then return end
	for k,v in pairs(basic.spriteset[setname]) do
		if k:sub(1,l)==spheader then
			--テクスチャの消去
			local r=basic.spriteset[setname][k]
			for i=0,r.cellnum-1 do
				basic_func.TDELETE(setname..":"..k..":"..i)
			end
			--スプライトデータの消去
			basic.spriteset[setname][k]=nil
			basic.spritesetsort(setname)
		end
	end
end
basic.registercom("SPVISIBLE","SN")
function basic_func.SPVISIBLE(name,visible)
	basic.createoffscreen()
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return
	end
	basic.spriteset[setname][spname].visible=visible
end
basic.registercom("SPANIMATIONRESET","")
function basic_func.SPANIMATIONRESET()
	for k,v in pairs(basic.spriteset) do
		for k2,v2 in pairs(v) do
			v2.count=gui.gettimer()
		end
	end
end
basic.registercom("SPCELL","SN")
function basic_func.SPCELL(name,cell)
	basic.createoffscreen()
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return
	end
	local r=basic.spriteset[setname][spname]
	if cell<0 then cell=0 elseif cell>=r.cellnum then cell=r.cellnum-1 end
	r.cell=cell
end
basic.registercom("SPMOVE","SNN.")
function basic_func.SPMOVE(name,x,y,a)
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return
	end
	basic.createoffscreen()
	a=a or 255
	local r=basic.spriteset[setname][spname]
	r.x=x
	r.y=y
	r.a=a
	r.cx=nil
	r.cy=nil
	r.xs=nil
	r.ys=nil
	r.rot=nil
end
basic.registercom("SPZ","SN")
function basic_func.SPZ(name,z)
	basic.createoffscreen()
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return
	end
	local r=basic.spriteset[setname][spname]
	r.z=z
	basic.spritesetsort(setname)
end
basic.registercom("SPFILL","SNS")
function basic_func.SPFILL(name,cell,color)
	basic.createoffscreen()
	basic_func.TFILL(name..":"..cell,color)
end

basic.registercom("SPMOVELT","SNNNNN.")
function basic_func.SPMOVELT(name,cx,cy,xs,ys,rot,a)
	basic.createoffscreen()
	a=a or 255
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return
	end
	local r=basic.spriteset[setname][spname]
	r.x=nil
	r.y=nil
	r.a=a
	r.cx=cx
	r.cy=cy
	r.xs=xs
	r.ys=ys
	r.rot=rot
end

function basic.__rotatepoint(x, y, cx, cy, rot)
    local tx = x - cx
    local ty = y - cy
    local cos_rot = math.cos(-rot)
    local sin_rot = math.sin(-rot)
    local rx = tx * cos_rot - ty * sin_rot
    local ry = tx * sin_rot + ty * cos_rot
    rx = rx + cx
    ry = ry + cy    
    return rx, ry
end
basic.registerfunc("SPHITCHECK","SNN")
function basic_func.SPHITCHECK(name,x,y)
	local setname,spname=basic.spnamesplit(name)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return 0
	end
	local r=basic.spriteset[setname][spname]
	if r.filtername then return 0 end
	if r.visible==0 then return 0 end
	local w,h=basic.texture[name..":"..r.cell]:getsize()
	if not r.x then
		local sw = w * r.xs
		local sh = h * r.ys
		local sx = r.cx - sw / 2
		local sy = r.cy - sh / 2
		local rot = r.rot
		if rot==0 then
			if sx<=x and sx+sw>=x and sy<=y and sy+h>=y then return 1 else return 0 end
		else
			local tx,ty = basic.__rotatepoint(x,y,r.cx,r.cy,-rot)
			if sx<=tx and sx+sw>=tx and sy<=ty and sy+h>=ty then return 1 else return 0 end
		end
	end
	if r.x<=x and r.x+w>=x and r.y<=y and r.y+h>=y then return 1 else return 0 end
end
basic.registercom("SPSET","SN.")
function basic_func.SPSET(setname,z,visible)
	if basic.spriteset[setname] then
		basic_func.SPSETDELETE(setname)
	end
	basic.spriteset[setname]={}
	basic.set_attr[setname]={}
	basic.set_attr[setname].z=z
	basic.set_attr[setname].visible=visible or 1
	if not basic.draworderset then basic.draworderset={} end
	basic.draworderset[setname]={}
	basic.spriteallsort()
end

basic.registercom("SPSETDELETE","S")
function basic_func.SPSETDELETE(setname)
	basic.createoffscreen()
	basic_func.SPSETCLEAR(setname)
	basic.spriteset[setname]=nil
	basic.set_attr[setname]=nil
	basic.spriteallsort()
end

basic.registercom("SPSETCLEAR","S")
function basic_func.SPSETCLEAR(setname)
	basic.createoffscreen()
	if not basic.spriteset[setname] then
		return
	end
	for k,v in pairs(basic.spriteset[setname]) do
		if setname=="" then
			basic_func.SPDELETE(k)
		else
			basic_func.SPDELETE(setname..":"..k)
		end
	end
	basic.spriteallsort()
end


basic.registercom("SPSETZ","SN")
function basic_func.SPSETZ(setname,z)
	basic.createoffscreen()
	if not basic.spriteset[setname] then
		return
	end
	basic.set_attr[setname].z=z
	basic.spriteallsort()
end
basic.registercom("SPSETVISIBLE","SN")
function basic_func.SPSETVISIBLE(setname,visible)
	basic.createoffscreen()
	if not basic.spriteset[setname] then
		return
	end
	basic.set_attr[setname].visible=visible
end
basic.registercom("GETSCREENSHOT","S")
function basic_func.GETSCREENSHOT(bmpname)
	--ビットマップにスクリーンショットを取得する。
	local bmp=basic.bitmap[bmpname]
	if bmp then
		bmp:delete()
	end
	local w,h=gui.getsize()
	bmp=bitmap.create(w,h)
	basic.SPDRAW_sub(bmp)
	basic.bitmap[bmpname]=bmp
end
basic.registercom("PRINT","SN*")
function basic_func.PRINT(typestr,tm,opt)
	--トランジションの実行
	if typestr=="" or typestr=="#C" then
		movie.resume()
		basic.SPDRAW_sub()
		basic.data.offscreenflag=false
		return
	end
	if not basic.data.offscreenflag then movie.resume() return end
	if not basic.data.offscreento then
		local w,h=gui.getsize()
		basic.data.offscreento=texture.create(w,h)
	end
	basic.SPDRAW_sub(basic.data.offscreento)
	local func=basic.transition_func[typestr]
	if not func then
		error("不正なトランジションタイプを指定しました。:"..typestr)
	end
	if func.init then func.init(opt) end
	local rate
	local st=gui.gettimer()
	local aoff,boff,xoff,yoff,startoff,backoff,l1off,r1off,l2off,r2off,l3off,r3off

	while true do
		local lu=gui.getclick()

		if basic.pad_enable==1 then
			local lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(0)
			if (not a) and (not aoff) then aoff=true end
			if (not b) and (not boff) then boff=true end
			if (not x) and (not xoff) then xoff=true end
			if (not y) and (not yoff) then yoff=true end
			if (not start) and (not startoff) then startoff=true end
			if (not back) and (not backoff) then backoff=true end
			if (not l1) and (not l1off) then l1off=true end
			if (not r1) and (not r1off) then r1off=true end
			if (l2==0) and (not l2off) then l2off=true end
			if (r2==0) and (not r2off) then r2off=true end
			if (not l3) and (not l3off) then l3off=true end
			if (not r3) and (not r3off) then r3off=true end
			if (a and aoff) or (b and boff) or (x and xoff) or (y and yoff) or (start and startoff) or (back and backoff) or (l1 and l1off) or (r1 and r1off) or (l2>0 and l2off) or (r2>0 and r2off) or (l3 and l3off) or (r3 and r3off) then
				lu=true
			end
		end

		if basic.skipmode==1 then break end
		if not gui.getkey("RETURN") and not retflag then retflag=true end
		if not gui.getkey(" ") and not spcflag then spcflag=true end
		if gui.getkey("RETURN") and retflag then lu=true end
		if gui.getkey(" ") and spcflag then lu=true end
		if gui.getkey("CTRL") then break end
		if lu then basic.skipmode=0 break end
		rate=(gui.gettimer()-st)/tm
		if rate<0.0 or rate>1.0 then break end
		draw.beginscene()
		func.draw(basic.data.offscreenfrom,basic.data.offscreento,rate)
		draw.endscene()
		gui.sleep(SLEEP_TIME)
		gui.doevents()
	end
	if func.delete then func.delete() end
	draw.beginscene()
	basic.data.offscreento:draw(0,0,255)
	draw.endscene()
	movie.resume()
	basic.data.offscreenflag=false
end
basic.transition_func={}
basic.transition_func["#F"]={draw=transition.fade}
basic.transition_func["#RU"]={draw=transition.rollup}
basic.transition_func["#RD"]={draw=transition.rolldown}
basic.transition_func["#RL"]={draw=transition.rollleft}
basic.transition_func["#RR"]={draw=transition.rollright}
basic.transition_func["#SU"]={draw=transition.slideup}
basic.transition_func["#SD"]={draw=transition.slidedown}
basic.transition_func["#SL"]={draw=transition.slideleft}
basic.transition_func["#SR"]={draw=transition.slideright}
local univrule
local function univinit (opt)
	univrule=bitmap.load(opt)
end
local function univdraw (from,to,rate)
	transition.universal(from,to,rate,univrule)
end
local function univdelete ()
	if univrule then univrule:delete() univrule=nil end
end
basic.transition_func["#U"]={init=univinit,delete=univdelete,draw=univdraw}


basic.registercom("SPDRAW","")
function basic_func.SPDRAW()
	basic.SPDRAW_sub()
end
basic.registercom("BTN","S*")
function basic_func.BTN(spname,param)
	--ボタンを設定する。
	if not param then param="" end
	local opt=basic.decodetable(param)
	local setname,spname=basic.spnamesplit(spname)
	if not basic.spriteset[setname] or not basic.spriteset[setname][spname] then
		return
	end
	local r=basic.spriteset[setname][spname]
	opt.style=opt.style or "push"
	r.btn=opt
end

--ボタンデータフォーマット
-- basic.spriteset[setname][spname].btn.～
-- style="push"(通常のプッシュボタン） "toggle"(トグルボタン) "bar"(デジタルスライドバー)
-- pushとtoggleはセル0と1を使う。
-- barは、同じ大きさの画像で、セルの数だけ横に分割される。

basic.registercom("BTNCLEAR","*")
function basic_func.BTNCLEAR(setname,defstr)
	--そのスプライトセットのボタン設定をクリアする
	if not setname then setname="" end
	if not basic.spriteset[setname] then
		error("存在しないスプライトセット"..setname.."を処理しようとしました。")
	end
	for k,v in pairs(basic.spriteset[setname]) do
		v.btn=nil
	end
	if defstr then
		basic.btndefstr[setname]=defstr
	else
		basic.btndefstr[setname]=nil
	end
end

function basic.hitcheck_all_btn(setname)
	local x,y=gui.getmouse()
	if x==nil or y==nil then return nil end
	local retname
	for j,t in ipairs(basic.draworder) do
		for i,v in ipairs(basic.draworderset[t.name]) do
			local spname
			if basic.spriteset[t.name][v.name].visible==1 then
				if t.name~="" then spname=t.name..":"..v.name else spname=v.name end
				if basic_func.SPHITCHECK(spname,x,y)==1 then
					if setname==t.name and basic.spriteset[t.name][v.name].btn then
						retname=v.name
					end
				end
			end
		end
	end
	return retname
end

function basic.BTNSTREXEC(str)
	for w in string.gmatch(str,"%u%b()") do
		local com,prm=w:match("^(%u)%((.*)%)$")
		com:upper()
		if com=="P" then
			if not prm then error ("不正なボタン動作文字列です。:"..str) end
			local sn,c=prm:match("^([_%w:]+),(%d+)$")
			if not sn or not c then
				sn=prm:match("^([_%w:]+)$")
				if not sn then
					error ("不正なボタン動作文字列です。:"..str)
				else
					--P(スプライト名)
					basic_func.SPVISIBLE(sn,1)
				end
			else
				--P(スプライト名,セル番)
				basic_func.SPVISIBLE(sn,1)
				basic_func.SPCELL(sn,tonumber(c))
			end
		elseif com=="C" then
			if not prm then error ("不正なボタン動作文字列です。:"..str) end
			--C(スプライト名)
			basic_func.SPVISIBLE(prm,0)
		elseif com=="M" then
			if not prm then error ("不正なボタン動作文字列です。:"..str) end
			local sn,x,y=prm:match("^([_%w:]+),([%+%-]*%d+),([%+%-]*%d+)$")
			if not sn or not x or not y then error ("不正なボタン動作文字列です。:"..str) end
			--M(スプライト名,x,y)
			basic_func.SPVISIBLE(sn,1)
			basic_func.SPMOVE(sn,tonumber(x),tonumber(y))
		elseif com=="S" then
			if not prm then error ("不正なボタン動作文字列です。:"..str) end
			--S(サウンドファイル名)
			if prm=="" then
				btn_f.btnse:stop()
			else
				btn_f.btnse:play{name=prm,volume=basic.data.sevol}
			end
		else
			error ("不正なボタン動作文字列です。:"..str)
		end
	end
end

local function btncompxy(a,b)
	local ax=a.x
	local bx=b.x
	if ax<bx then return true end
	if ax>bx then return false end
	if a.y<b.y then return true end
	return false
end

local function btncompyx(a,b)
	local ay=a.y
	local by=b.y
	if ay<by then return true end
	if ay>by then return false end
	if a.x<b.x then return true end
	return false
end

local function btnexec_setmouse(setname,spname)
	local sp=basic.spriteset[setname][spname]
	local tname
	if setname~="" then
		tname=setname..":"..spname..":0"
	else
		tname=spname..":0"
	end
	local w,h=basic.texture[tname]:getsize()
	if sp then
		gui.setmouse(math.floor(sp.x+w/2),math.floor(sp.y+h/2))
	end
end

basic.registercom("BTNEXEC","R*")
function basic_func.BTNEXEC(vname,setname,param)

	local framecounter=0
	if basic.data.offscreenflag then
		basic_func.PRINT("#C")
	end

	local opt
	local begintime=gui.gettimer()
	local voicemode=basic.sound["VOICE"]:isplaying()
	local funcoff={}
	local escoff,spcoff,retoff,curoff=false,false,false,false
	local aoff,boff,xoff,yoff,startoff,backoff,l1off,r1off,l2off,r2off,l3off,r3off
	setname=setname or ""

	local key_off={}

	if param then
		opt=basic.decodetable(param)
	else
		opt={}
	end
	for k,v in pairs(basic.spriteset[setname]) do
		if v.btn and v.btn.style=="push" then
			v.cell=0
		end
	end
	if not setname then setname="" end
	if not basic.spriteset[setname] then
		error("存在しないスプライトセット"..setname.."を処理しようとしました。")
	end

	if basic.btndefstr[setname] then
		basic.BTNSTREXEC(basic.btndefstr[setname])
	end

	local nowsp=nil
	local beforesp
	local r
	local ret

	local orderx={} -- X方向優先のオーダー（上下で使う）
	local ordery={} -- Y方向優先のオーダー（左右で使う）

	for i,v in ipairs(basic.draworderset[setname]) do
		local nm=v.name
		if basic.spriteset[setname][nm].btn then
			local btn = basic.spriteset[setname][nm]
			orderx[#orderx+1]={name=nm,x=btn.x or btn.cx,y=btn.y or btn.cy}
			ordery[#ordery+1]={name=nm,x=btn.x or btn.cx,y=btn.y or btn.cy}
		end
	end

	table.sort(orderx,btncompxy)
	table.sort(ordery,btncompyx)

	if basic.set_attr[setname].visible==0 then
		basic.set_attr[setname].visible=1
	end
	local	lu,ru,w,ld,rd
	local	lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3

	local screenmode=gui.getscreenmode()

	while true do
		movie.resume()

		beforesp=nowsp
		nowsp=basic.hitcheck_all_btn(setname)
		if beforesp and nowsp~=beforesp then
			r=basic.spriteset[setname][beforesp]
			if r.btn.style=="push" then
				r.cell=0
			end
			if r.btn.off then basic.BTNSTREXEC(r.btn.off) end
		end
		if nowsp and nowsp~=beforesp then
			r=basic.spriteset[setname][nowsp]
			if r.btn.style=="push" and r.cellnum>1 then
				r.cell=1
			end
			beforesp=nowsp
			if r.btn.on then basic.BTNSTREXEC(r.btn.on) end
		end
		if basic.btndefstr[setname] and not nowsp and nowsp~=beforesp then
			basic.BTNSTREXEC(basic.btndefstr[setname])
		end
		ret=nil

		lu,ru,w,ld,rd=gui.getclick()

		if basic.pad_enable==1 then
			lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(0)
			if (not aoff) and (not a) then aoff=true end
			if (not boff) and (not b) then boff=true end
			if (not xoff) and (not x) then xoff=true end
			if (not yoff) and (not y) then yoff=true end
			if (not startoff) and (not start) then startoff=true end
			if (not backoff) and (not back) then backoff=true end
			if (not l1off) and (not l1) then l1off=true end
			if (not r1off) and (not r1) then r1off=true end
			if (not l2off) and (l2==0) then l2off=true end
			if (not r2off) and (r2==0) then r2off=true end
			if (not l3off) and (not l3) then l3off=true end
			if (not r3off) and (not r3) then r3off=true end
		end

		if opt.spcret~=1 then
			if spcoff==false and gui.getkey(" ")==false then spcoff=true end
			if retoff==false and gui.getkey("RETURN")==false then retoff=true end
			if spcoff==true and gui.getkey(" ")==true then ru=true end
			if retoff==true and gui.getkey("RETURN")==true then lu=true end
		end
		if escoff==false and gui.getkey("ESC")==false then escoff=true end
		if escoff==true and gui.getkey("ESC")==true then ru=true end

		if basic.pad_enable==1 then
			if a and aoff then ret="#PAD_A" end
			if b and boff then ret="#PAD_B" end
			if x and xoff then ret="#PAD_X" end
			if y and yoff then ret="#PAD_Y" end
			if start and startoff then ret="#PAD_START" end
			if back and backoff then ret="#PAD_BACK" end
			if l1 and l1off then ret="#PAD_L1" end
			if r1 and r1off then ret="#PAD_R1" end
			if l2>0 and l2off then ret="#PAD_L2" end
			if r2>0 and r2off then ret="#PAD_R2" end
			if l3 and l3off then ret="#PAD_L3" end
			if r3 and r3off then ret="#PAD_R3" end
		end

		if lu then
			basic.skipmode=0
			if nowsp==nil then
				ret=""
			else
				ret=nowsp
				r=basic.spriteset[setname][nowsp]
				if r.btn.style=="toggle" then
					r.cell=1-r.cell
					ret=ret..":"..r.cell
				elseif r.btn.style=="bar" then
					local texname
					if setname~="" then texname=setname..":"..nowsp else texname=nowsp end
					texname=texname..":0"
					local w,h=basic.texture[texname]:getsize()
					local x,y=gui.getmouse()
					local newcell
					if not r.btn.align or r.btn.align=="left" then
						newcell=math.floor((x-r.x)*(r.cellnum-1)/w+0.5)
					elseif r.btn.align=="right" then
						newcell=math.floor((r.x+w-x)*(r.cellnum-1)/w+0.5)
					else
						error("バーの設定がおかしいです。")
					end
					if newcell>=r.cellnum then r.cell=r.cellnum-1 else r.cell=newcell end
					ret=ret..":"..r.cell
				end
				if r.cell>=r.cellnum then r.cell=r.cellnum-1 elseif r.cell<0 then r.cell=0 end
				if r.btn.style=="push" and r.btn.notreset~=1 then r.cell=0 end
			end
		end
		if opt.wheel==1 then
			if w<0 then ret="#WU" end
			if w>0 then ret="#WD" end
		end
		if opt.automode==1 then
			if not opt.time then error("オートモードの時間が設定されていません。") end
			if not voicemode then
				local t=gui.gettimer()-begintime
				if t>opt.time or t<0 then
						ret="#TIMEOUT"
				end
			elseif voicemode and (not basic.sound["VOICE"]:isplaying()) then
				ret="#TIMEOUT"
			end
		else
			if opt.time then
				local t=gui.gettimer()-begintime
				if t>opt.time or t<0 then
						ret="#TIMEOUT"
				end
			end
		end
		if ru then ret="#R" end
		if opt.ldown==1 and ld then
			ret="#LD"
		end
		if opt.rdown==1 and rd then ret="#RD" end

		if opt.ctrl==1 and gui.getkey("CTRL") then ret="#CTRL" end

		if opt.spcret==1 then
			if spcoff==false and gui.getkey(" ")==false then spcoff=true end
			if retoff==false and gui.getkey("RETURN")==false then retoff=true end
			if spcoff==true and gui.getkey(" ")==true then ret="#SPACE" end
			if retoff==true and gui.getkey("RETURN")==true then ret="#RETURN" end
		end

		if opt.func==1 then
			for i=1,12 do
				if not funcoff[i] and gui.getkey("F"..i)==false then funcoff[i]=true end
				if funcoff[i] and gui.getkey("F"..i)==true then ret="#F"..i end
			end
		end

		if opt.sizechange==1 then
			if gui.getscreenmode()~=screenmode then ret="#SIZECHANGE" end
		end


		if opt.alphabet then
			for i=1,26 do
				local b=gui.getkey(string.char(64+i))
				if key_off[i] then
					if not b then ret="#KEY_"..string.char(64+i) end
				else
					if b then key_off[i]=b end
				end
			end
		end

		if opt.cursor then
			if gui.getkey("LEFT") then
					ret="#LEFT"
			elseif gui.getkey("RIGHT") then
				ret="#RIGHT"
			elseif gui.getkey("DOWN") then
				ret="#DOWN"
			elseif gui.getkey("UP") then
				ret="#UP"
			end
		else
			if #orderx>0 then
				if gui.getkey("LEFT") then
					if curoff then
						curoff=false
						local now=0
						if nowsp then
							for i,v in ipairs(ordery) do
								if v.name==nowsp then
									now=i
								end
							end
						end
						now=now-1
						if now<1 then now=#ordery end
						btnexec_setmouse(setname,ordery[now].name)
					end
				elseif gui.getkey("RIGHT") then
					if curoff then
						curoff=false
						local now=0
						if nowsp then
							for i,v in ipairs(ordery) do
								if v.name==nowsp then
									now=i
								end
							end
						end
						now=now+1
						if now>#ordery then now=1 end
						btnexec_setmouse(setname,ordery[now].name)
					end
				elseif gui.getkey("UP") then
					if curoff then
						curoff=false
						local now=0
						if nowsp then
							for i,v in ipairs(orderx) do
								if v.name==nowsp then
									now=i
								end
							end
						end
						now=now-1
						if now<1 then now=#orderx end
						btnexec_setmouse(setname,orderx[now].name)
					end
				elseif gui.getkey("DOWN") then
					if curoff then
						curoff=false
						local now=0
						if nowsp then
							for i,v in ipairs(orderx) do
								if v.name==nowsp then
									now=i
								end
							end
						end
						now=now+1
						if now>#orderx then now=1 end
						btnexec_setmouse(setname,orderx[now].name)
					end
				else
					curoff=true
				end
			end
		end
		basic.sprite_animation_check()
		basic.SPDRAW_sub()
		if ret then break end
		gui.sleep(SLEEP_TIME)
		gui.doevents()
		if not curoff then
			framecounter=framecounter+1
			if framecounter>60 then
				curoff=true
				framecounter=0
			end
		else
			framecounter=0
		end
	end
	basic.vset(vname,ret)
	basic.SPDRAW_sub()
end

basic.registercom("WAIT","N.")
function basic_func.WAIT(mili,clickskip)
	--時間待ち命令。アニメがある場合それも実行する。
	movie.resume()
	if not clickskip or clickskip==0 then clickskip=false else clickskip=true end
	local st=gui.gettimer()

	local aoff,boff,xoff,yoff,startoff,backoff,l1off,r1off,l2off,r2off,l3off,r3off

	while true do
		basic.sprite_animation_check()
		basic.SPDRAW_sub()
		gui.doevents()
		local t=gui.gettimer()
		if t>=st+mili or t<st then break end
		if clickskip then
			local l=gui.getclick()

		if basic.pad_enable==1 then
			local lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(0)
			if (not a) and (not aoff) then aoff=true end
			if (not b) and (not boff) then boff=true end
			if (not x) and (not xoff) then xoff=true end
			if (not y) and (not yoff) then yoff=true end
			if (not start) and (not startoff) then startoff=true end
			if (not back) and (not backoff) then backoff=true end
			if (not l1) and (not l1off) then l1off=true end
			if (not r1) and (not r1off) then r1off=true end
			if (l2==0) and (not l2off) then l2off=true end
			if (r2==0) and (not r2off) then r2off=true end
			if (not l3) and (not l3off) then l3off=true end
			if (not r3) and (not r3off) then r3off=true end
			if (a and aoff) or (b and boff) or (x and xoff) or (y and yoff) or (start and startoff) or (back and backoff) or (l1 and l1off) or (r1 and r1off) or (l2>0 and l2off) or (r2>0 and r2off) or (l3 and l3off) or (r3 and r3off) then
				l=true
			end
		end


			if l then basic.skipmode=0 break end
			if gui.getkey("CTRL") or basic.skipmode==1 then break end
		end
		gui.sleep(SLEEP_TIME)
		movie.render()
	end
end

basic.registercom("CLICK","")
function basic_func.CLICK()
	--左クリック待ち命令。アニメがある場合それも実行する。
	--リターンキーは左クリック扱いになる。

	local aoff,boff,xoff,yoff,startoff,backoff,l1off,r1off,l2off,r2off,l3off,r3off

	if basic.data.offscreenflag then
		basic_func.PRINT("#C")
	end

	local retflag=false
	while true do
		basic.sprite_animation_check()
		basic.SPDRAW_sub()
		if gui.getkey("RETURN") then retflag=true end
		if retflag and not gui.getkey("RETURN") then break end
		local l=gui.getclick()

		if basic.pad_enable==1 then
			local lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(0)
			if (not a) and (not aoff) then aoff=true end
			if (not b) and (not boff) then boff=true end
			if (not x) and (not xoff) then xoff=true end
			if (not y) and (not yoff) then yoff=true end
			if (not start) and (not startoff) then startoff=true end
			if (not back) and (not backoff) then backoff=true end
			if (not l1) and (not l1off) then l1off=true end
			if (not r1) and (not r1off) then r1off=true end
			if (l2==0) and (not l2off) then l2off=true end
			if (r2==0) and (not r2off) then r2off=true end
			if (not l3) and (not l3off) then l3off=true end
			if (not r3) and (not r3off) then r3off=true end
			if (a and aoff) or (b and boff) or (x and xoff) or (y and yoff) or (start and startoff) or (back and backoff) or (l1 and l1off) or (r1 and r1off) or (l2>0 and l2off) or (r2>0 and r2off) or (l3 and l3off) or (r3 and r3off) then
				l=true
			end
		end

		if l then basic.skipmode=0 break end
		if gui.getkey("CTRL") then break end
		gui.doevents()
		gui.sleep(SLEEP_TIME)
	end
end

basic.registercom("LRCLICK","?R")
function basic_func.LRCLICK(ret)
	--左右クリック待ち命令。アニメがある場合それも実行する。
	--左クリックのとき#L 右クリックのとき#Rを返す。
	--スペースキーは右クリック　リターンキーは左クリック扱いになる。
	--パッドの場合は常に左クリック扱いになる（パッドで細かい制御をしたい場合は自前で判断すること）
	local aoff,boff,xoff,yoff,startoff,backoff,l1off,r1off,l2off,r2off,l3off,r3off

	local l,r
	local spcoff,retoff=false,false
	if basic.data.offscreenflag then
		basic_func.PRINT("#C")
	end

	while true do
		basic.sprite_animation_check()
		basic.SPDRAW_sub()
		l,r=gui.getclick()
		local sp=gui.getkey(" ")
		local rt=gui.getkey("RETURN")
		if spcoff==false and sp==false then spcoff=true end
		if spcoff==true and sp==true then l=true end
		if retoff==false and rt==false then retoff=true end
		if retoff==true and rt==true then r=true end
		if basic.pad_enable==1 then
			local lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(0)
			if (not a) and (not aoff) then aoff=true end
			if (not b) and (not boff) then boff=true end
			if (not x) and (not xoff) then xoff=true end
			if (not y) and (not yoff) then yoff=true end
			if (not start) and (not startoff) then startoff=true end
			if (not back) and (not backoff) then backoff=true end
			if (not l1) and (not l1off) then l1off=true end
			if (not r1) and (not r1off) then r1off=true end
			if (l2==0) and (not l2off) then l2off=true end
			if (r2==0) and (not r2off) then r2off=true end
			if (not l3) and (not l3off) then l3off=true end
			if (not r3) and (not r3off) then r3off=true end
			if (a and aoff) or (b and boff) or (x and xoff) or (y and yoff) or (start and startoff) or (back and backoff) or (l1 and l1off) or (r1 and r1off) or (l2>0 and l2off) or (r2>0 and r2off) or (l3 and l3off) or (r3 and r3off) then
				l=true
			end
		end

		if l then basic.skipmode=0 end
		if l or r then break end
		gui.doevents()
		gui.sleep(SLEEP_TIME)
	end
	if ret then
		if l then
			basic.vset(ret,"#L")
		else
			basic.vset(ret,"#R")
		end
	end
end

------------------------------------
-- フォント処理
------------------------------------

--フォントパラメータテーブル設定時のチェック関数。シンボルによる色指定の数値への変換などもしている。

function FONT_CHECK(opt)
	opt.width=opt.width or 16
	opt.height=opt.height or 16
	if not opt.style then
		opt.color=opt.color or "#FFFFFFFF"
	end
	if opt.color then opt.color=basic.htmlcolor_to_number(opt.color) end
	if opt.color1 then opt.color1=basic.htmlcolor_to_number(opt.color1) end
	if opt.color2 then opt.color2=basic.htmlcolor_to_number(opt.color2) end
	if opt.outlinecolor then opt.outlinecolor=basic.htmlcolor_to_number(opt.outlinecolor) end
	if opt.shadowcolor then opt.shadowcolor=basic.htmlcolor_to_number(opt.shadowcolor) end
end

basic.registercom("FONT","ST")
function basic_func.FONT(name,param)
	local opt=basic.decodetable(param)
	opt.fx=basic.number_to_boolean(opt.fx)
	opt.fy=basic.number_to_boolean(opt.fy)

	FONT_CHECK(opt)
	basic.fontparam[name]=opt
	basic.fontstr[name]=param
end
basic.registercom("FDELETE","S")
function basic_func.FDELETE(name)
	basic.fontparam[name]=nil
	basic.fontstr[name]=nil
end

--putflag=trueのとき用保存変数

----------------------------------------------
-- フォントのフォーマット出力
----------------------------------------------

local SPCHAR=encoding.utf8_to_utf16("{/}\\")--表示文用特殊文字
local SPCHAR2=encoding.utf8_to_utf16("pnf")--表示文用特殊文字

--逐次表示保存用
local p_target
local p_code
local p_ptr
local p_textx
local p_texty
local p_opt
local p_rubyopt
local p_textf
local p_rubyf

-----------------------
-- ノベルモード関連
-----------------------
basic.registercom("NOVELMODE","N")
function basic_func.NOVELMODE(mode)
	if mode==0 then basic.novelmode=0 else basic.novelmode=1 end
end

basic.registercom("NEWPAGE","")
function basic_func.NEWPAGE()
	basic.clearflag=true
	lastlog.text=lastlog.text.."\\f"
end

basic.registercom("GETTEXTPOS","RR")
function basic_func.GETTEXTPOS(xv,yv)
	--改行後の値を返す。
	basic.vset(xv,p_opt.x)
	basic.vset(yv,p_texty+p_opt.py)
end

basic.registercom("SKIPPAUSE","N")
function basic_func.SKIPPAUSE(mode)
	if mode==0 then basic.skippause=0 else basic.skippause=1 end
end


function basic.FONT_PUT_FORMAT(target,str,opt,rubyopt,putflag)
	--putflag=trueは、テクスチャに書き込みながら表示する逐次表示モードであることを表す。
	--falseの場合は画像を書き込むだけで逐次表示はしない。
	--targetは、偽で呼ばれる場合は継続処理、前の設定のまま続きを実行。

	local code
	local ptr
	local textx,texty
	local textf,rubyf

	if target then
		--新規処理
		if putflag and basic.textautopauseflag==1 then
			--表示文字列処理
			if str:sub(-1,-1)=="_" then
				str=str:sub(1,-2)
			elseif str:sub(-2,-1)~="\\f" then
				--\fの場合は\pを付与しない
				str=str.."\\p"
			end
		end

		code=encoding.utf8_to_utf16(str)
		ptr=1

		opt.x=opt.x or 0
		opt.y=opt.y or 0
		if not opt.font then
			error("テキストにフォントの設定がされていません。")
		end
		opt.fp=basic.fontparam[opt.font]
		if not opt.fp then
			error("テキストのフォントが未定義です。")
		end
		if rubyopt and rubyopt.font then
			rubyopt.fp=basic.fontparam[rubyopt.font]
			if not rubyopt.fp then error("ルビフォントが未定義です。") end
		end
		opt.fw=opt.fp.width
		opt.fh=opt.fp.height
		opt.px=opt.px or opt.fw -- 横送り幅
		opt.py=opt.py or opt.fh -- 縦送り幅
		opt.wait=opt.wait or 0 --ウェイト

		--フォントのデフォルト設定
		opt.fp.color = opt.fp.color or 0xFFFFFFFF
		opt.fp.shadowcolor = opt.fp.shadowcolor or 0xFF000000
		opt.fp.shadowx = opt.fp.shadowx or 1
		opt.fp.shadowy = opt.fp.shadowy or 1
		opt.fp.outlinecolor = opt.fp.outlinecolor or 0xFF000000
		opt.fp.color1 = opt.fp.color1 or 0xFFFFFFFF
		opt.fp.color2 = opt.fp.color2 or 0xFFFFFF88

		if rubyopt then
			rubyopt.px=rubyopt.fp.px or rubyopt.fp.width
			rubyopt.py=rubyopt.fp.py or rubyopt.fp.height
			rubyopt.fp.color = rubyopt.fp.color or 0xFFFFFFFF
			rubyopt.fp.shadowcolor = rubyopt.fp.shadowcolor or 0xFF000000
			rubyopt.fp.shadowx = rubyopt.fp.shadowx or 1
			rubyopt.fp.shadowy = rubyopt.fp.shadowy or 1
			rubyopt.fp.outlinecolor = rubyopt.fp.outlinecolor or 0xFF000000
			rubyopt.fp.color1 = rubyopt.fp.color1 or 0xFFFFFFFF
			rubyopt.fp.color2 = rubyopt.fp.color2 or 0xFFFFFF88
		end

		--文字数設定
		if not opt.w or not opt.h then
			local w,h=target:getsize()
			opt.w=opt.w or math.floor((w-opt.x)/opt.px)
			opt.h=opt.h or math.floor((h-opt.y)/opt.py)
		end
		textf=font.create(opt.fp)

		if putflag then
			--逐次表示なので設定を全部保存する
			p_target=target
			p_code=code
			p_opt=opt
			p_rubyopt=rubyopt
			p_textf=textf
			p_rubyf=rubyf
			if basic.novelmode==0 or basic.clearflag==true then
				--逐次モード改ページ処理
				target:fill(0)
				--表示開始位置
				textx=opt.x
				texty=opt.y
				--フラグクリア
				basic.clearflag=false
			else
				--逐次モード改行処理
				textx=opt.x
				texty=p_texty+opt.py --前回のY座標を受け継ぐ
			end
		else
				--一括モードなので先頭へ。
				textx=opt.x
				texty=opt.y
		end
		--ルビチェック　存在するならルビ空白を開けて表示しなければならない。
		local rubyexist=false
		for i,v in ipairs(code) do
			if v==SPCHAR[1] then
				rubyexist=true
				break
			end
		end
		if rubyexist then
			if not rubyopt or not rubyopt.fp then
				error("表示文にルビがありますが、ルビ用フォントが正しく設定されていません。")
			end
			rubyf=font.create(rubyopt.fp)
			texty=texty+rubyopt.py
			opt.py=opt.py+rubyopt.py
		end

	else
		--逐次・継続処理
		target=p_target
		code=p_code
		opt=p_opt
		rubyopt=p_rubyopt
		textf=p_textf
		rubyf=p_rubyf
		textx=p_textx
		texty=p_texty
		ptr=p_ptr
		putflag=true
	end

	if basic.skipmode==1 then opt.wait=0 end --スキップモード時

	local rubytext={}
	local rubystart
	local rubyend
	local rubyy

	local retoff,spcoff=false,false
	local aoff,boff,xoff,yoff,startoff,backoff,l1off,r1off,l2off,r2off,l3off,r3off

	while true do
		if not retoff and not gui.getkey("RETURN") then retoff=true end
		if not spcoff and not gui.getkey(" ") then spcoff=true end
		--表示していく
		local c=code[ptr]
		if c==nil then
			if rubymode~=nil then
				error("ルビが正しく記述されていません。")
			end
			p_textx = textx
			p_texty = texty
			break
		end
		if c==SPCHAR[1] and rubymode==nil then
			--ルビ処理開始記号
			ptr=ptr+1
			rubymode=1
			rubystart=textx
			rubyy=texty-rubyopt.py
		elseif c==SPCHAR[2] and rubymode==1 then
			--ルビ中間記号
			ptr=ptr+1
			rubymode=2
			if textx>rubystart then
				rubyend=textx
			else
				rubyend=opt.x+opt.w*opt.px-1
			end
		elseif c==SPCHAR[3] and rubymode==2 then
			--ルビ終端記号
			ptr=ptr+1
			rubymode=nil
			--ルビ文字描画
			--座標計算
			if (rubyend-rubystart)/#rubytext<rubyopt.px then
				--ルビ対象幅を広げる
				local rcenter=rubystart+(rubyend-rubystart)/2
				rubystart=rcenter-math.floor(#rubytext*rubyopt.px/2)
				if rubystart<opt.x then rubystart=opt.x end
				rubyend=rubystart+#rubytext*rubyopt.px
				if rubyend>opt.x+opt.w*opt.px then
					basic.exec_return()
					error("ルビが画面右端を超えてしまいました。ルビの前に改行してください。")
				end
			end
			local rubyp=(rubyend-rubystart)/#rubytext
			local rubyofs=(rubyp-rubyopt.px)/2
			for i,v in ipairs(rubytext) do
				FONT_PUT_CODE(target,rubyf,v,rubystart+rubyp*(i-1)+rubyofs,rubyy,rubyopt)
			end
			rubytext={}
		elseif c==SPCHAR[4] and code[ptr+1]~=SPCHAR[4] then
			--特殊文字
			ptr=ptr+1
			c=code[ptr]
			if c==SPCHAR2[1] then
				--クリック待ち
				ptr=ptr+1
				if putflag and (basic.novelmode==0 or basic.skippause==0) then
					if opt.wait==0 then
						--逐次表示でwait=0の場合はレンダリング
						basic.SPDRAW_sub()
					end
					p_textx=textx
					p_texty=texty
					p_ptr=ptr
					if basic.novelmode==0 then
						basic.exec_textgosub(textx,texty)
					else
						basic.exec_textgosub(textx,texty,0)
					end
					return
				end
			elseif c==SPCHAR2[2] then
				--改行
				ptr=ptr+1
				textx=opt.x
				texty=texty+opt.py
				if texty>=opt.y+opt.h*opt.py then
					basic.exec_return()
					error("文字が指定範囲からはみ出しました。")
				end
			elseif c==SPCHAR2[3] then
				--改ページクリック待ち
				ptr=ptr+1
				if putflag then
					if basic.novelmode==0 then
						basic.exec_return()
						error("改ページクリック待ちはノベルモードでしか使えません。")
					end
					p_ptr=ptr
					basic.clearflag=true
					if opt.wait==0 then
						--逐次表示でwait=0の場合はレンダリング
						basic.SPDRAW_sub()
					end
					basic.exec_textgosub(textx,texty,1)
					return
				end
			else
				error("不正な特殊表示文字です。")
			end
		else
			--普通の文字
			if rubymode~=2 then
				FONT_PUT_CODE(target,textf,c,textx,texty,opt)
				if c==SPCHAR[4] then ptr=ptr+1 end -- \\ のときのみここを通る
				ptr=ptr+1
				--禁則判定
				textx=textx+opt.px
				local kinsokunum=0
				while true do
					local flag=false
					for n,h in ipairs(HLCHAR) do
						if h==code[ptr+kinsokunum] then flag=true end
					end
					for n,h in ipairs(HFCHAR) do
						if h==code[ptr+kinsokunum+1] then flag=true end
					end
					if flag then kinsokunum=kinsokunum+1 else break end
				end
				if textx+kinsokunum*opt.px>=opt.x+opt.w*opt.px then
					textx=opt.x
					texty=texty+opt.py
					if texty>=opt.y+opt.h*opt.py then
						basic.exec_return()
						error("文字が指定範囲からはみ出しました。")
					end
				end
				if putflag and opt.wait>0 then
					local l=gui.getclick()

					if basic.pad_enable==1 then
						local lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(0)
						if (not a) and (not aoff) then aoff=true end
						if (not b) and (not boff) then boff=true end
						if (not x) and (not xoff) then xoff=true end
						if (not y) and (not yoff) then yoff=true end
						if (not start) and (not startoff) then startoff=true end
						if (not back) and (not backoff) then backoff=true end
						if (not l1) and (not l1off) then l1off=true end
						if (not r1) and (not r1off) then r1off=true end
						if (l2==0) and (not l2off) then l2off=true end
						if (r2==0) and (not r2off) then r2off=true end
						if (not l3) and (not l3off) then l3off=true end
						if (not r3) and (not r3off) then r3off=true end
						if (a and aoff) or (b and boff) or (x and xoff) or
								(y and yoff) or (start and startoff) or (back and backoff) or
								(l1 and l1off) or (r1 and r1off) or (l2>0 and l2off) or
								(r2>0 and r2off) or (l3 and l3off) or (r3 and r3off) then
							l=true
						end
					end

					if l then basic.skipmode=0 opt.wait=0 end
					if retoff and gui.getkey("RETURN") then basic.skipmode=0 opt.wait=0 end
					if spcoff and gui.getkey(" ") then basic.skipmode=0 opt.wait=0 end
					if gui.getkey("CTRL") then opt.wait=0 end
				end
				--一文字ずつ表示の場合はここでウェイト
				if putflag and opt.wait>0 then
					basic_func.WAIT(opt.wait,false)
				end
			else
				--ルビ文字なのでテーブルに保存していく
				rubytext[#rubytext+1]=c
				ptr=ptr+1
			end
		end
	end
	--逐次表示でwait=0の場合はレンダリング
	if putflag and opt.wait==0 then
		basic.SPDRAW_sub()
	end
	if putflag then
		--オフスクリーンバッファをクリア
		basic.data.offscreenflag=false
	end
end

basic.registercom("TFORMAT","SST.")
function basic_func.TFORMAT(tname,str,param,rparam)
	local t=basic.texture[tname]
	local opt=basic.decodetable(param)
	local ropt
	if rparam then
		ropt=basic.decodetable(rparam)
	end
	if not t then error("存在しないテクスチャ\""..tname.."\"を処理しようとしました。") end
	basic.FONT_PUT_FORMAT(t,str,opt,ropt,false)
end
basic.registercom("BFORMAT","SST.")
function basic_func.BFORMAT(bname,str,param,rparam)
	local b=basic.bitmap[bname]
	local opt=basic.decodetable(param)
	local ropt
	if rparam then
		ropt=basic.decodetable(rparam)
	end
	if not b then error("存在しないビットマップ\""..tname.."\"を処理しようとしました。") end
	basic.FONT_PUT_FORMAT(b,str,opt,ropt,false)
end

basic.registercom("SPFORMAT","SNST.")
function basic_func.SPFORMAT(name,cell,str,param,rparam)
	basic_func.TFORMAT(name..":"..cell,str,param,rparam)
end

basic.registercom("SPPUTTEXT","SNST.")
function basic_func.SPPUTTEXT(name,cell,str,param,rparam)
	local tname=name..":"..cell
	local t=basic.texture[tname]
	local opt=basic.decodetable(param)
	local rpot
	if rparam then
		ropt=basic.decodetable(rparam)
	end
	if not t then error("存在しないテクスチャ\""..tname.."\"を処理しようとしました。") end
	if basic.data.offscreenflag then
		basic_func.PRINT("#C")
	end
	basic.FONT_PUT_FORMAT(t,str,opt,ropt,true)
end


------------------------------------
-- スキップ関連
------------------------------------
basic.registercom("SKIP","N")
function basic_func.SKIP(mode)
	basic.skipmode=mode
end

basic.registerfunc("GETSKIP","")
function basic_func.GETSKIP()
	gui.doevents()
	local aoff,boff,xoff,yoff,startoff,backoff,l1off,r1off,l2off,r2off,l3off,r3off
	if basic.skipmode~=0 then
		if gui.getclick() then basic.skipmode=0 return 0 end
		if basic.pad_enable==1 then
			local lx,ly,rx,ry,dx,dy,a,b,x,y,start,back,l1,r1,l2,r2,l3,r3=gui.getpad(0)
			if (not a) and (not aoff) then aoff=true end
			if (not b) and (not boff) then boff=true end
			if (not x) and (not xoff) then xoff=true end
			if (not y) and (not yoff) then yoff=true end
			if (not start) and (not startoff) then startoff=true end
			if (not back) and (not backoff) then backoff=true end
			if (not l1) and (not l1off) then l1off=true end
			if (not r1) and (not r1off) then r1off=true end
			if (l2==0) and (not l2off) then l2off=true end
			if (r2==0) and (not r2off) then r2off=true end
			if (not l3) and (not l3off) then l3off=true end
			if (not r3) and (not r3off) then r3off=true end
			if (a and aoff) or (b and boff) or (x and xoff) or (y and yoff) or (start and startoff) or (back and backoff) or (l1 and l1off) or (r1 and r1off) or (l2>0 and l2off) or (r2>0 and r2off) or (l3 and l3off) or (r3 and r3off) then
				basic.skipmode=0
				return 0
			end
		end
	end
	return basic.skipmode
end

------------------------------------
-- フィルタ処理
------------------------------------
function basic_filter.init_NEGA(handle,opt)
	--特に何もしない
end
function basic_filter.delete_NEGA(handle,opt)
	--特に何もしない
end
function basic_filter.draw_NEGA(handle,opt,outbmp)
	outbmp:nega()
end
function basic_filter.init_MONOTONE(handle,opt)
	--特に何もしない
end
function basic_filter.delete_MONOTONE(handle,opt)
	--特に何もしない
end
function basic_filter.draw_MONOTONE(handle,opt,outbmp)
	outbmp:monotone(basic.htmlcolor_to_number(opt.color))
end

------------------------------------
-- 演出命令
------------------------------------

basic.registercom("QUAKE","*")
function basic_func.QUAKE(time,num,size)
	local w,h=gui.getsize()
	num=num or 8
	size=size or 1
	time=time or 500
	local wait=time/num
	if basic.skipmode==1 or gui.getkey("CTRL") then return end
	basic.createoffscreen()
	for i=1,num do
		local x=(math.random(math.floor(w/16))*size-math.floor(w/32))
		local y=(math.random(math.floor(h/16))*size-math.floor(h/32))
		draw.beginscene()
		basic.data.offscreenfrom:drawlt(w/2+x,h/2+y,1+0.07*size,1+0.07*size,0,255)
		draw.endscene()
		gui.doevents()
		gui.sleep(wait)
	end
	movie.resume()
	basic.SPDRAW_sub()
end

--------------------------------------------------------------------
-- ■■セーブ・ロード処理■■
--------------------------------------------------------------------
function basic.obj_init()
	--ロード時・リセット時に共通で使う、Lua側の内部状態初期化関数
	basic.backlog={}
	basic.backlogheader=1
	basic.sound={}
	basic.bgmname=""
	basic.bgvname={}
	basic.seloopname={}
	basic.bitmap={}
	basic.texture={}
	basic.spriteset={}
	basic.set_attr={}
	basic.btndefstr={}
	basic_func.SPSET("",10000,1)
	basic.sound["BGM0"]=sound.create()
	basic.sound["BGM1"]=sound.create()
	for i=0,15 do
		basic.sound["SE"..i]=sound.create()
		basic.sound["BGV"..i]=sound.create()
	end
	basic.sound["VOICE"]=sound.create()
	if basic.data.offscreenfrom then basic.data.offscreenfrom:delete() end
	if basic.data.offscreento then basic.data.offscreento:delete() end
	basic.data.offscreenfrom=nil
	basic.data.offscreento=nil
	basic.data.offscreenflag=false
	basic.skipmode=0
	basic.lastcaption=""
	collectgarbage("collect")
	basic.skippause=0
	basic.novelmode=0
end

function basic.onreset()
	basic.obj_init()
end

function basic.onsaveload(issave)
	if issave then
		if basic.novelmode==1 and (not basic.clearflag) then
			error "セーブポイント更新はノベルモードでは改ページ直後にしか実行できません。"
		end
		--キャプションのセーブ
		basic.serialize(basic.lastcaption)
		--バックログのセーブ
		basic.serialize(basic.backlogheader)
		basic.serialize(#basic.backlog)
		for i=1,#basic.backlog do
			basic.serialize(basic.backlog[i].tag)
			basic.serialize(basic.backlog[i].text)
		end
		--サウンドのセーブ
		basic.serialize(basic.bgmname)
		for i=0,15 do
			if basic.bgvname[i] then
				basic.serialize(i)
				basic.serialize(basic.bgvname[i])
			end
		end
		basic.serialize(-1)
		for i=0,15 do
			if basic.seloopname[i] then
				basic.serialize(i)
				basic.serialize(basic.seloopname[i])
			end
		end
		basic.serialize(-1)

		--スプライトのセーブ
		for k,v in pairs(basic.spriteset) do
			basic.serialize(k)
			basic.serialize(basic.set_attr[k].z)
			basic.serialize(basic.set_attr[k].visible)
			for k2,v2 in pairs(v) do
				basic.serialize(k2)
				basic.serialize(v2.str)
				basic.serialize(v2.x)
				basic.serialize(v2.y)
				basic.serialize(v2.z)
				basic.serialize(v2.a)
				basic.serialize(v2.cell)
				basic.serialize(v2.cx)
				basic.serialize(v2.cy)
				basic.serialize(v2.xs)
				basic.serialize(v2.ys)
				basic.serialize(v2.rot)
				basic.serialize(v2.delete)
			end
			basic.serialize(0)
		end
		basic.serialize(0)
		basic.serialize(basic.data.bgmfadeout)
		basic.serialize(basic.data.sefadeout)
		basic.serialize(basic.data.bgvfadeout)
		basic.serialize(basic.novelmode)
	else
		basic.obj_init()
		--キャプションのロード
		basic.lastcaption=basic.serialize()
		basic_func.CAPTION(basic.lastcaption)
		--バックログのロード
		basic.backlogheader=basic.serialize()
		local n=basic.serialize()
		for i=1,n do
			basic.backlog[i]={}
			basic.backlog[i].tag=basic.serialize()
			basic.backlog[i].text=basic.serialize()
		end
		--サウンドのロード
		local v=basic.serialize()
		if v~="" then basic_func.BGMPLAY(v) end
		while true do
			local i=basic.serialize()
			if i==-1 then break end
			local str=basic.serialize()
			basic_func.BGVPLAY(i,str)
		end
		while true do
			local i=basic.serialize()
			if i==-1 then break end
			local str=basic.serialize()
			basic_func.SELOOP(i,str)
		end
		--スプライトのロード
		while true do
			k=basic.serialize()
			if k==0 then break end
			local spsetz=basic.serialize()
			local spsetv=basic.serialize()
			basic_func.SPSET(k,spsetz,spsetv)
			while true do
				local k2=basic.serialize()
				if k2==0 then break end
				str=basic.serialize()
				local tbl=basic.decodetable(str)
				basic.SP_sub(k,k2,tbl)
				local r=basic.spriteset[k][k2]
				r.str=str
				r.x=basic.serialize()
				r.y=basic.serialize()
				r.z=basic.serialize()
				r.a=basic.serialize()
				r.cell=basic.serialize()
				r.cx=basic.serialize()
				r.cy=basic.serialize()
				r.xs=basic.serialize()
				r.ys=basic.serialize()
				r.rot=basic.serialize()
				r.delete=basic.serialize()
			end
		end
		basic.data.bgmfadeout=basic.serialize()
		basic.data.sefadeout=basic.serialize()
		basic.data.bgvfadeout=basic.serialize()
		basic.novelmode=basic.serialize()
		basic.spriteallsort()
		basic.SPDRAW_sub()
		movie.reset()
		basic.clearflag=true -- ロード時にはクリアフラグは必ずtrueである。
	end
end

function basic.onsystemsaveload(issave)
	local v
	if issave then
		for k,v in pairs(basic.filelog) do
			basic.serialize(k)
		end
		basic.serialize(0)
		basic.serialize(basic.data.bgmvol)
		basic.serialize(basic.data.voicevol)
		basic.serialize(basic.data.sevol)
		basic.serialize(basic.data.bgvvol)
		basic.serialize(gui.getscreenmode())
		basic.serialize(basic.skippause)
	else
		basic.filelog={}
		while true do
			v=basic.serialize()
			if v==0 then break end
			basic.filelog[v]=true
		end
		basic.data.bgmvol=basic.serialize()
		basic.data.voicevol=basic.serialize()
		basic.data.sevol=basic.serialize()
		basic.data.bgvvol=basic.serialize()
		gui.setscreenmode(basic.serialize())
		basic.skippause=basic.serialize()
	end
end
