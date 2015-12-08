Swift2.0でMetal入門

新しいグラフィックスAPI「Metal」の入門的内容です。
XcodeでMetalを試す場合Gameプロジェクトで始めることができますが、いきなり大量のコードが目に入るのためそっとファイルを閉じたくなりますよね。

今回はSingle View Applicationから、順番に設定しMetalを使えるところまで持っていきます。

このガイドは[Learning iOS 8 Game Development Using Swift](http://www.amazon.co.jp/Learning-Game-Development-Using-Swift-ebook/dp/B00YJ64GCO)を参考に解説しています。
この本はGame開発だけでなく、iOSでのグラフィックスの扱い方を解説しているおすすめの良書です！

### 参考サイト
はじめる前に下記のページもおすすめです。

+ [DSAS開発者の部屋](http://dsas.blog.klab.org/archives/52168969.html)
詳細な解説あります。わからない用語はこちらで調べながら進めると良いでしょう。
+ [iOSの新グラフィックAPI - Metal入門してみる](http://qiita.com/edo_m18/items/0fd6971c98c27a125d6e)
こちらもおすすめです。


ざっくり解説なので、興味が出てきたら細かいところを調べてみるとより理解が進むと思います。


### 実装時の注意点
Metalの実装は必ず各デバイスで行ってください。Macのシュミレーターでは動きません。
(最新のOS10.11では未確認です)


### 新規プロジェクトを作成
まずは、新規プロジェクトを作ります。「Single View Application」を選択してください。

![687474703a2f2f7777772e7765686561727473776966742e636f6d2f77702d636f6e74656e742f75706c6f6164732f323031342f30362f6372656174652d612d73696e676c652d706167652d6170706c69636174696f6e2e706e67.png](https://qiita-image-store.s3.amazonaws.com/0/15535/83731d25-90e8-63fa-f4a9-438218a48c3b.png "687474703a2f2f7777772e7765686561727473776966742e636f6d2f77702d636f6e74656e742f75706c6f6164732f323031342f30362f6372656174652d612d73696e676c652d706167652d6170706c69636174696f6e2e706e67.png")


### ライブラリを設定

Builde PhasesでMetalのライブラリ一式設定します。
![lib.png](https://qiita-image-store.s3.amazonaws.com/0/15535/9b81e1c8-5e35-7837-24d0-45bbcdba65e6.png "lib.png")

QuartzCoreはCAMetalLayerを使うため設定します。
(CoreAnimation系はQuartzCoreフレームワークが必要になるようです。)


### 下準備
グラフィックスライブラリ系はOpenGL然り、いろいろな下準備が必要です。
なるべく必要最小限の設定で進めたいと思います。

まずはライブラリの読み込み設定をします。

```swift
import UIKit
import Metal
import QuartzCore
```

つぎにMetalのコードを記述します。
今回のコードはすべてViewControllerのviewDidLoad()メソッド内に記述します。
まずは、ViewControllerを開きます。

Metalを利用するにあたって、必ず必要となるコードを準備します。

<b>MTLDevice</b>
MTLCreateSystemDefaultDevice()でデバイスを取得します。これで直接デバイスに対してアクセスできます。

```swift
let device: MTLDevice? = MTLCreateSystemDefaultDevice()
```

<b>MTLCommandQueue</b>
レンダリングコマンドをGPUに流すためのキューです。キューが保持するコマンドを順番に処理し、描画を進めていきます。

```swift
let commandQueue: MTLCommandQueue!  = device.newCommandQueue()
```

### リソースの準備
次にリソースの準備をします。描画系でリソースと言われたら頂点座標リストかテクスチャです。
ここでは頂点座標を準備します。今回は2Dの三角形を描画します。

```swift
let vertexArray: [Float] = [
    0.0, 0.1,
    -0.1, -0.1,
    0.1, -0.1
]
```

VertexArrayはViewControllerクラスの外側で定義しておきます。
頂点座標を元に画面上に図形を描画します。


### 頂点Bufferを作る
頂点座標は準備できましたが、これをグラフィックスライブラリで扱うにはVertex Bufferに格納します。
Metalでは<b>MTLBUffer</b>です。頂点数と頂点の型(今回はFloat)から格納するメモリを準備しています。
このあたりは、こういうものをしなければいけない程度で大丈夫です。

```swift
var vertexBuffer: MTLBuffer! = device.newBufferWithBytes( vertexArray,
    length: vertexArray.count * sizeofValue(vertexArray[0]),
    options: MTLResourceOptions.OptionCPUCacheModeDefault
)
```

### Shaderを作る
Shaderとは頂点の変換やピクセルの色付けなど、グラフィックスに関する計算処理をまとめたものです。
もちろんShaderを使わないくてもグラフィックス処理を進めることはできます。使わない場合はCPUに計算させるのですがピクセルの処理などは膨大な計算量になるので、すぐにパフォーマンスの問題にぶつかります。
(画面サイズ100x100に描画する場合は、ピクセル処理は10000にも及びます)

そこでShaderはGPUを利用して計算させます。これは非常に高速です。Shaderを利用するのはここが理由です。

シェーダーは2種類あります。"Vertex shader"と"Fragment shader"です。
ここでは、以下の点だけ理解で進みます。とりあえずはこんなものでも大丈夫です。

+ Vertex shader: 頂点の移動、回転の変換処理
+ Fragment shader: 各ピクセルの処理をする(1pxごとに処理を実行)

さっそくShaderを作ってみます。
一般的にShaderのファイルは2種類用意しますが(VertexとFragment)、Metalでは一つのファイルにまとめることができます。もちろん２ファイルに分けてもよいです。今回は1ファイルにまとめます。Shader.metalを作ります。

```cpp

// スタンダードライブラリを読み込む
#include <metal_stdlib>

// 識別子metalを省略できる設定
using namespace metal;  

// VertexShader
// 頂点の計算処理　入力の座標に対して特に何もしません。
vertex float4 myVertexShader(const device float2 * vertex_array [[ buffer(0) ]], uint vid [[ vertex_id ]]) {
    return float4(vertex_array[vid],0,1);
}

// Fragment Shader
// 各ピクセルの処理 黒でぬりつぶします。別名Pixel Shaderとも呼ばれます。
fragment float4 myFragmentShader() {
    return float4(0.0, 0.0, 0.0, 1.0); // 図形ないの各ピクセルの色を指定します。
}
```

Shader.metalはC++11の記述のようです。
二つの関数がありますが、それらがShader処理です。

2つの関数の先頭にどのShaderであるか表す"vertex"、"fragment"という識別子がつきます。
関数の記述方法は

(Shader識別子) (戻り値) 関数名(引数){
	// 処理内容
}

といった形になります。
今回はShaderの処理内容は細かく解説しません。 
Shaderではいくつか特殊な型を持ちます。

+ float, float2, flaot3, float4
+ int, int2, int3, int4
+ vert1, vert2...

vertは変数です。
float4は4つのfloat値要素をもった構造値と考えれば問題ないと思います。
たとえば、x,y,z,w(四元数）やr,g,b,a(色)などです。
このあたりは初見では難しいとおもうので、とりあえず次へ移動します。

このShaderファイルはコンパイル時にShader Libraryに追加されます。これによってShaderの再コンパイルを防ぎ、効率化を図ります。Shader Libraryにはdeviceからアクセスできます。

```swift
let defaultLibrary = device.newDefaultLibrary()
let newVertexFunction = defaultLibrary!.newFunctionWithName("myVertexShader")
let newFragmentFunction = defaultLibrary?.newFunctionWithName("myFragmentShader")
```

Shader関数名も取得していますが、これは後ほど使います。


次に描画パイプラインを作ります。pipeline descriptorを作ります。これはFile記述子と同じように、
これを経由して描画処理を進めます。

```swift
let pipelineStateDescriptor = MTLRenderPipelineDescriptor()

// 頂点処理を設定
pipelineStateDescriptor.vertexFunction      = newVertexFunction

// ピクセル処理を設定
pipelineStateDescriptor.fragmentFunction    = newFragmentFunction

// 色成分の順序を設定
pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm 

// RenderPipelineの状態を取得
var pipelineState: MTLRenderPipelineState!
do {
   pipelineState = try device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
} catch {
   print("error with device.newRenderPipelineStateWithDescriptor")
}
```

MetalのPixelFormatについて詳しく知りたい人は、[こちら](https://developer.apple.com/library/ios/documentation/Metal/Reference/MetalConstants_Ref/#//apple_ref/c/tdef/MTLPixelFormat)をご確認ください。

### CAMetalLayerを作る

描画結果を出力するために、ViewにCAMetalLayerを追加します。
こいつでエラーが出る場合は、そのデバイスではMetalが使えない場合があります。
(Apple A7チップ以降であれば使えます。)

```swift
let metalLayer = CAMetalLayer()
metalLayer.device = device
metalLayer.pixelFormat = .BGRA8Unorm   // pipeline descriptorに設定したものと同じものを設定する。
metalLayer.frame = view.layer.frame     // フレームサイズを設定
view.layer.addSublayer(metalLayer)
```

これで描画の準備ができました。


### 描画処理


ここから描画に入ります。
まず最初にCAMetalLayerから描画エリアの参照を取得します。

```swift
let drawable = metalLayer.nextDrawable()
```

次にRender Descriptorを作ります。

```swift
let renderPassDescriptor = MTLRenderPassDescriptor()
```

描画するテクスチャを設定します。

```swift
renderPassDescriptor.colorAttachments[0].texture = drawable?.texture
```

フレームがloadされた時の処理を設定します。

```swift
renderPassDescriptor.colorAttachments[0].loadAction = .Clear // 毎フレームクリアされる
```

クリアカラーを設定、この色でlayerが塗りつぶされ、その上に再度描画されます。

```swift
renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 1.0,
            green: 1.0,
            blue: 1.0,
            alpha: 1.0
)
```

次に、layerに三角形を描画します。
commandQueueからcommandBufferを取得します。

```swift
let commandBuffer = commandQueue.commandBuffer()
```

全てのcommandはマシン語に変換しなければなりません。
これはMTLRenderCommandEncoderを利用します。

```swift
let renderEncoder: MTLRenderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor
```

RenderPipelineStateを設定し、頂点Bufferをセットします。

```swift
renderEncoder.setRenderPipelineState(pipelineState)
renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)     
```

これで三角形を描画できる準備が整いました。長かった...

```swift
renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1); // 描画
```

Render Encodingを終了します。

```swift
renderEncoder.endEncoding()
```

まだ画面には表示されてないので、表示するようにメソッドを実行します。
commit()でテクスチャが反映されます。

```swift
commandBuffer.presentDrawable(drawable!)
commandBuffer.commit()
```

これで完了です。今回作成したコードは[こちらでも確認できます。](https://github.com/SuguruSasaki/MetalTempalte)


最後はちょっと駆け足になりましたが、OpenGLと比べるとMetalの方が入門しやすい気がしました。
情報自体は、まだまだWeb上にも十分なものが少なく、コード自体はObjective-cのものが多いです。
今後を考えればSwiftでの学習がおすすめです。

OpenGLを試してみるとグラフィッキスライブラリとはどうゆうものか、より理解もできます。

グラフィックスライブラリは決してGameだけのものではないので、多くの開発者が試してくれることを期待しています。

この記事の続きは[こちらのアドベントカレンダー](http://qiita.com/advent-calendar/2015/quad-inc)でも続けます。






