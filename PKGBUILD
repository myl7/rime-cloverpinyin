# Maintainer: fkxxyz <fkxxyz@163.com>
# Maintainer: myl7 <myl@myl.moe>

pkgname=rime-cloverpinyin
pkgver=1.2.0
pkgrel=2
pkgdesc="Clover Simplified pinyin input for rime"
arch=('x86_64')
url="https://www.fkxxyz.com/d/cloverpinyin/"
license=('LGPL')
depends=('rime-prelude' 'rime-emoji' 'rime-symbols')
makedepends=('librime')
source=(https://github.com/fkxxyz/rime-cloverpinyin/releases/download/${pkgver}/clover.schema-${pkgver}.zip)
sha256sums=('03fec7f7653a1e37b12c23a5c8bf30c9bf299c8f5530424f63a5c03b31656a7a')

build(){
  cd $srcdir
  rime_deployer --compile clover.schema.yaml . /usr/share/rime-data
}

package() {
  cd $srcdir
  rm build/*.txt
  rm -rf opencc
  install -Dm644 *.yaml -t "$pkgdir"/usr/share/rime-data/
  install -Dm644 build/* -t "$pkgdir"/usr/share/rime-data/build/
}
