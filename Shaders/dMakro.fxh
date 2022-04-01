/*
                              __                __
                         ____/ /___ ___  ____ _/ /___________
                        / __  / __ `__ \/ __ `/ //_/ ___/ __ \
                       / /_/ / / / / / / /_/ / ,< / /  / /_/ /
                       \__,_/_/ /_/ /_/\__,_/_/|_/_/   \____/

                      fungsi makro untuk user interface ReShade
                              dibuat ama mbah.primbon

                              disponsori oleh UnFamouS
    ////////////////////////////////////////////////////////////////////////////

    LU MUSTI TAU :
    ==============
    Sebelum ke panduan penggunaan nya, pertama gua mau bilang bodo amat ama orang
    luar brow, kaga peduli mau dibilang apa ama mereka, ini file gua suka-suka gua.
    fakyeu mennn maderpaker.

    Oke sekarang kita ke tutorialnya.


    Cara menggunakan makro ini :
    ============================
    Pertama, tambahin file ini kedalam shader lu dengan cara #include file ini.
    Pastiin ini ada di bagian atas, lebih bagus ada dibawah ReShade.fxh

    contoh nih,

    #include "ReShade.fxh"
    #include "dMakro.fxh"
    #include "AseDeKon.h"
    #include ....

    Bisa dilihat diatas kalau dMakro.fxh ditambahin dibawah ReShade.fxh.
    sisanya dibawah suka-suka lu misalkan lu pake banyak hal.

    "Kenapa kudu gitu bang ?, kenapa ga dipaling atas aja biar estetik ?"
    Ya biar ga error lah, makro lu perlu variabel parameter yang ada di ReShade.fxh.
    Jadi ReShade.fxh itu harus duluan yang musti dipanggil ama shader lu.

    Ada beberapa tipe variabel yang didukung ama ini makro. Lebih
    lengkapnya lu bisa liat daftar dibawah ini :

      Tipe / Jenis Variabel :
      -----------------------
      MP_BOOL    = Boolean

      MP_INT     = Integer
      MP_INT2    = Integer (2 komponen)
      MP_INT3    = Integer (3 komponen)
      MP_INT4    = Integer (4 komponen)

      MP_FLOAT   = Floating Point
      MP_FLOAT2  = Floating Point (2 komponen)
      MP_FLOAT3  = Floating Point (3 komponen)
      MP_FLOAT4  = Floating Point (4 komponen)

      MP_COMBO   = Kombinasi Item
      MP_RADIO   = Opsi Item
      MP_LIST    = Daftar Item

      MP_COLOR   = Warna
      MP_TEXT    = Teks

    Nah setelah itu ada juga beberapa jenis Widget yang dimiliki ama UI nya ReShade
    diantaranya adalah sebagai berikut :

      Jenis - jenis widget UI ReShade :
      ---------------------------------
      S          = Slider (bisa dipake di jenis variabel float dan integer)
      I          = Input  (bisa dipake di jenis variabel float dan integer)
      D          = Drag   (bisa dipake di jenis variabel float dan integer)

      R          = Radio  (cuma bisa dipake di jenis variabel integer)
      C          = Combo  (cuma bisa dipake di jenis variabel integer)
      L          = List   (cuma bisa dipake di jenis variabel integer)

    Kalau kalian liat untuk widget S (Slider), I (Input) dan D (Drag) itu bisa
    dipakai di kedua jenis variabel float dan int. Sedangkan untuk R (Radio),
    C (Combo), L (List) itu hanya bisa digunakan pada jenis variabel integer.

    Jujur aja, jenis widget I (Input) itu widget yang jarang dipake, kuno banget bro,
    sekarang UI sudah gampang dan lebih nyaman dipake bro tinggal ser-geser
    set sat set aja buat edit. Kaga musti lu input angka spesifik. Kalo lu mau
    override rentang value yang ada di dalam variabel itu, gua lebih menyarankan elu
    untuk menggunakan widget D (Drag), why ? karena lu bisa ser-geser buat ngubah
    valuenya, dan lu bisa input dengan cara double click di variabel parameternya.

    Okehh.. mungkin lu sekarang agak bingung, kenapa ini namanya dipersingkat
    MP_INT, MP_FLOAT dll untuk jenis variabel nya, dan satu huruf S, I, D, R, C, L untuk
    jenis widgetnya. Misal lu butuh makro dengan jenis float dan widget slider,
    tinggal pake MP_FLOAT_S(), atau lu perlu float3 dengan widget drag, jadinya
    MP_FLOAT3_D() kalo mau diubah dari drag ke slider tinggal ubah aja D ke S,
    seperti itu. Ini kan makro ya bro, fungsi nya makro itu adalah menyederhanakan
    sesuatu yang belibet banget bro.

    Jadi setelah lu mengerti apa jenis variabel makro nya sekarang gua akan contohin
    gimana misalkan lu perlu makro ini untuk variabel parameter shader elu.

    (File shader tutorialnya ada di paket penjualan, kalian bisa cek sendiri.)

    Fitur kategorisasi, kalau lu mau parameterlu punya kategori, tinggal panggil
    definisi KATEGORISASI. Caranya tinggal tulis aja di bagian atas sebelum include
    dengan nambahin line #define KATEGORISASI. ini berfungsi untuk mengaktifkan
    kategorinya.

    Setelah itu di setiap kelompok parameter, lu kasih #define KATEGORI(x, y).
    x itu mewakili nama kategori yang bakal lu pakai, dan y itu untuk fungsi buka
    tutup kategori (diisi, buka / tutup / true / false). setelah itu kasih #undef
    di bagian bawah setiap kategorinya.

*/

//// VERSION CHECKING //////////////////////////////////////////////////////////

#define DMAKRO_VERSION          1023

#define RESHADE __RESHADE__
#define VERSION(MAJOR, MINOR, REVISION) \
  (MAJOR * 10000 + MINOR * 100 + REVISION)

#if DMAKRO_VERSION_REQUIREMENT < DMAKRO_VERSION
 #error "You are using an outdated dMakro.fxh"
 #error "Please download updated version from github.com/dddfault/dMakro"
#endif

#if !defined(DMAKRO_VERSION_REQUIREMENT)
 #error "Incompatible dMakro.fxh version. (dMakro might be missing on this shader)"
 #error "Please check requirement version."
#endif

#if !defined(RESHADE) || RESHADE < RESHADE_VERSION_REQUIREMENT
	#error "Incompatible ReShade version."
  #error "Please check requirement version above."
#endif

//// API AND GPU VENDOR ////////////////////////////////////////////////////////

#define API  __RENDERER__
#if   ((API >= 0x9000)  && (API < 0xA000))
    #define D3D9 API
#elif ((API >= 0xA000)  && (API < 0xB000))
    #define D3D10 API
#elif ((API >= 0xB000)  && (API < 0xC000))
    #define D3D11 API
#elif ((API >= 0xC000)  && (API < 0xD000))
    #define D3D12 API
#elif ((API >= 0x10000) && (API < 0x20000))
    #define OpenGL API
#elif ((API >= 0x20000) && (API < 0x30000))
    #define Vulkan API
#endif

#define GPU  __VENDOR__
#if   ((GPU == 0x1002) && (GPU == 0x1022))
  #define AMD GPU
#elif (GPU == 0x10DE)
  #define NVIDIA GPU
#elif (GPU == 0x8086)
  #define INTEL GPU
#endif

//// TEMPLATE UI RESHADE ///////////////////////////////////////////////////////

#define ui_reshade(jenis_data, nama_variabel, anotasi, value_bawaan) \
    uniform jenis_data nama_variabel < anotasi > = value_bawaan

#define mp_jenis_widget(m)   ui_type     = ""#m;
#define mp_label(m)          ui_label    = ""##m;
#define mp_tooltip(m)        ui_tooltip  = ""##m;
#define mp_teks(m)           ui_text     = ""##m;
#define mp_items(m)          ui_items    = ""##m;
#define mp_jarak(m)          ui_spacing  = m;
#define mp_minimal(m)        ui_min      = m;
#define mp_maksimal(m)       ui_max      = m;
#define mp_step(m)           ui_step     = m;
#define mp_value(m)					              (m);

#ifdef KATEGORISASI
  #define mp_kategori(m, p) \
   ui_category        = ##m;\
   ui_category_closed = p;
#else
  #define mp_kategori(m, p) \
  ui_category         = ""; \
  ui_category_closed = false;
#endif

#define null
#define kosong
#define buka    false
#define tutup   true

//// RESHADE BASE //////////////////////////////////////////////////////////////

#define MP_BASE_UI(jenis_data, nama_variabel, jenis_widget, label, tooltip, teks, items, jarak, minimal, maksimal, step, value_bawaan) \
    ui_reshade(jenis_data, nama_variabel, \
      mp_jenis_widget(jenis_widget)       \
      mp_label(label)                     \
      mp_tooltip(tooltip)                 \
      mp_teks(teks)                       \
      mp_items(items)                     \
      mp_kategori(KATEGORI, TERTUTUP)     \
      mp_jarak(jarak)                     \
      mp_minimal(minimal)                 \
      mp_maksimal(maksimal)               \
      mp_step(step),                      \
      mp_value(value_bawaan))

//// FLOAT /////////////////////////////////////////////////////////////////////
#define MP_FLOAT_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)


#define MP_FLOAT2_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float2, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT2_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float2, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT2_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float2, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT2_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float2, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)


#define MP_FLOAT3_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float3, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT3_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float3, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT3_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float3, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT3_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float3, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)


#define MP_FLOAT4_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float4, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT4_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float4, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT4_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float4, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_FLOAT4_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(float4, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

//// INTEGER ///////////////////////////////////////////////////////////////////

#define MP_INT_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)


#define MP_INT2_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int2, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT2_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int2, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT2_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int2, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT2_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int2, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)


#define MP_INT3_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int3, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT3_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int3, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT3_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int3, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT3_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int3, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)


#define MP_INT4_R(nama_variabel, jenis_widget, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int4, nama_variabel, jenis_widget, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT4_S(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int4, nama_variabel, slider, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT4_I(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int4, nama_variabel, input, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

#define MP_INT4_D(nama_variabel, label, tooltip, teks, jarak, minimal, maksimal, step, value_bawaan) \
	MP_BASE_UI(int4, nama_variabel, drag, label, tooltip, teks, null, jarak, minimal, maksimal, step, value_bawaan)

//// BOOLEAN | COMBO | RADIO | LIST | COLOR | TEXT /////////////////////////////

#define MP_BOOL(nama_variabel, label, tooltip, teks, jarak, value_bawaan) \
	MP_BASE_UI(bool, nama_variabel, null, label, tooltip, teks, null, jarak, 0, 0, 0, value_bawaan)

#define MP_COMBO(nama_variabel, label, tooltip, teks, items, jarak, minimal, maksimal, value_bawaan) \
	MP_BASE_UI(int, nama_variabel, combo, label, tooltip, teks, items, jarak, minimal, maksimal, 0, value_bawaan)

#define MP_RADIO(nama_variabel, label, tooltip, teks, items, jarak, minimal, maksimal, value_bawaan) \
	MP_BASE_UI(int, nama_variabel, radio, label, tooltip, teks, items, jarak, minimal, maksimal, 0, value_bawaan)

#define MP_LIST(nama_variabel, label, tooltip, teks, items, jarak, minimal, maksimal, value_bawaan) \
	MP_BASE_UI(int, nama_variabel, list, label, tooltip, teks, items, jarak, minimal, maksimal, 0, value_bawaan)

#define MP_COLOR(nama_variabel, label, tooltip, teks, jarak, value_bawaan) \
  MP_BASE_UI(float3, nama_variabel, color, label, tooltip, teks, null, jarak, 0, 1, 1, value_bawaan)

#define MP_TEXT(nama_variabel, teks, jarak) \
  MP_BASE_UI(int, nama_variabel, radio, " ", null, teks, null, jarak, 0, 0, 0, 0) \

#ifdef KATEGORI
  #undef  KATEGORI
#endif

#ifdef TERTUTUP
  #undef  TERTUTUP
#endif
