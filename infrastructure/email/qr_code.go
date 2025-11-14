package infrastructure

import (
	"os"
	"github.com/skip2/go-qrcode"
)



func CreateQR()  {
	data := "https://pornhub.com"
	qr_code, _ := qrcode.Encode(data, qrcode.Highest, 256)
	file, _ := os.Create("qr.png")
	defer file.Close()
	file.Write(qr_code)
}