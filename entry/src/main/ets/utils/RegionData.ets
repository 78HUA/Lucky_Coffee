// 省市区数据（内置子集，带真实行政区划代码，用作地址的 areaCode）
// 说明：后端没有地区接口，验收图里的三列选择器就是本地数据。
//      这里给 8 个省、每省若干市、每市若干区，机制完整、够演示；
//      将来要全国全量，只替换下面这份数据即可（对外只暴露 4 个函数）。

export interface RegionDistrict {
  name: string;
  code: string; // 真实行政区划代码，例如天河区 = 440106
}

export interface RegionCity {
  name: string;
  districts: RegionDistrict[];
}

export interface RegionProvince {
  name: string;
  cities: RegionCity[];
}

export const REGIONS: RegionProvince[] = [
  {
    name: '广东省',
    cities: [
      {
        name: '广州市',
        districts: [
          { name: '天河区', code: '440106' },
          { name: '越秀区', code: '440104' },
          { name: '海珠区', code: '440105' },
          { name: '白云区', code: '440111' },
          { name: '番禺区', code: '440113' }
        ]
      },
      {
        name: '深圳市',
        districts: [
          { name: '南山区', code: '440305' },
          { name: '福田区', code: '440304' },
          { name: '宝安区', code: '440306' },
          { name: '龙岗区', code: '440307' }
        ]
      },
      {
        name: '韶关市',
        districts: [
          { name: '浈江区', code: '440204' },
          { name: '武江区', code: '440203' },
          { name: '曲江区', code: '440205' }
        ]
      }
    ]
  },
  {
    name: '湖南省',
    cities: [
      {
        name: '长沙市',
        districts: [
          { name: '岳麓区', code: '430104' },
          { name: '芙蓉区', code: '430102' },
          { name: '天心区', code: '430103' },
          { name: '开福区', code: '430105' }
        ]
      },
      {
        name: '株洲市',
        districts: [
          { name: '天元区', code: '430211' },
          { name: '荷塘区', code: '430202' }
        ]
      },
      {
        name: '湘潭市',
        districts: [
          { name: '雨湖区', code: '430302' },
          { name: '岳塘区', code: '430304' }
        ]
      }
    ]
  },
  {
    name: '湖北省',
    cities: [
      {
        name: '武汉市',
        districts: [
          { name: '武昌区', code: '420106' },
          { name: '洪山区', code: '420111' },
          { name: '江汉区', code: '420103' },
          { name: '汉阳区', code: '420105' }
        ]
      },
      {
        name: '宜昌市',
        districts: [
          { name: '西陵区', code: '420502' },
          { name: '伍家岗区', code: '420503' }
        ]
      },
      {
        name: '襄阳市',
        districts: [
          { name: '襄城区', code: '420602' },
          { name: '樊城区', code: '420606' }
        ]
      }
    ]
  },
  {
    name: '广西壮族自治区',
    cities: [
      {
        name: '南宁市',
        districts: [
          { name: '青秀区', code: '450103' },
          { name: '兴宁区', code: '450102' },
          { name: '西乡塘区', code: '450107' }
        ]
      },
      {
        name: '桂林市',
        districts: [
          { name: '秀峰区', code: '450302' },
          { name: '象山区', code: '450304' }
        ]
      },
      {
        name: '柳州市',
        districts: [
          { name: '城中区', code: '450202' },
          { name: '鱼峰区', code: '450203' }
        ]
      }
    ]
  },
  {
    name: '海南省',
    cities: [
      {
        name: '海口市',
        districts: [
          { name: '美兰区', code: '460108' },
          { name: '龙华区', code: '460106' },
          { name: '琼山区', code: '460107' }
        ]
      },
      {
        name: '三亚市',
        districts: [
          { name: '吉阳区', code: '460203' },
          { name: '天涯区', code: '460204' }
        ]
      }
    ]
  },
  {
    name: '江西省',
    cities: [
      {
        name: '南昌市',
        districts: [
          { name: '东湖区', code: '360102' },
          { name: '西湖区', code: '360103' },
          { name: '青山湖区', code: '360111' }
        ]
      },
      {
        name: '赣州市',
        districts: [
          { name: '章贡区', code: '360702' },
          { name: '南康区', code: '360703' }
        ]
      }
    ]
  },
  {
    name: '福建省',
    cities: [
      {
        name: '福州市',
        districts: [
          { name: '鼓楼区', code: '350102' },
          { name: '台江区', code: '350103' },
          { name: '仓山区', code: '350104' }
        ]
      },
      {
        name: '厦门市',
        districts: [
          { name: '思明区', code: '350203' },
          { name: '湖里区', code: '350206' }
        ]
      }
    ]
  },
  {
    name: '浙江省',
    cities: [
      {
        name: '杭州市',
        districts: [
          { name: '西湖区', code: '330106' },
          { name: '上城区', code: '330102' },
          { name: '滨江区', code: '330108' },
          { name: '余杭区', code: '330110' }
        ]
      },
      {
        name: '宁波市',
        districts: [
          { name: '海曙区', code: '330203' },
          { name: '江北区', code: '330205' }
        ]
      }
    ]
  }
];

// ===== 对外只暴露这 4 个函数（选择器三列 + 取 areaCode） =====

// 省名列表（选择器第一列）
export function provinceNames(): string[] {
  return REGIONS.map((p: RegionProvince): string => p.name);
}

// 某省下的市名列表（选择器第二列）
export function cityNames(province: string): string[] {
  const target: RegionProvince | undefined =
    REGIONS.find((p: RegionProvince) => p.name === province);
  if (target === undefined) {
    return [];
  }
  return target.cities.map((c: RegionCity): string => c.name);
}

// 某市下的区县名列表（选择器第三列）
export function districtNames(province: string, city: string): string[] {
  const targetP: RegionProvince | undefined =
    REGIONS.find((p: RegionProvince) => p.name === province);
  if (targetP === undefined) {
    return [];
  }
  const targetC: RegionCity | undefined =
    targetP.cities.find((c: RegionCity) => c.name === city);
  if (targetC === undefined) {
    return [];
  }
  return targetC.districts.map((d: RegionDistrict): string => d.name);
}

// 取行政区划代码（保存地址时作为 areaCode 传给后端；查不到就回空串）
export function areaCodeOf(province: string, city: string, district: string): string {
  const targetP: RegionProvince | undefined =
    REGIONS.find((p: RegionProvince) => p.name === province);
  if (targetP === undefined) {
    return '';
  }
  const targetC: RegionCity | undefined =
    targetP.cities.find((c: RegionCity) => c.name === city);
  if (targetC === undefined) {
    return '';
  }
  const targetD: RegionDistrict | undefined =
    targetC.districts.find((d: RegionDistrict) => d.name === district);
  return targetD === undefined ? '' : targetD.code;
}
