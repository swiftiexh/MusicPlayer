export interface  ColorModel{
  dark: string;
  bright: string;
  gray: string;
  background: string;
}

export const dayModel: ColorModel = {
  dark: "#100005",
  bright: "#ffffff",
  gray: "#7e7e7e",
  background: '#f1f5f8'
};

export const nightModel: ColorModel = {
  dark: "#ffffff",
  bright: "#1b1b1b",
  gray: "#b9b9b9",
  background: "#0d0d0d"
};