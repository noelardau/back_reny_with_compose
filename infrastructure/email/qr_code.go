package infrastructure

import (
	"fmt"
	"os"
	"github.com/skip2/go-qrcode"
)



func CreateQR(id_reservation string)  {
	data := fmt.Sprintf("http://localhost:3001/resa/one/%s", id_reservation)
	qr_code, _ := qrcode.Encode(data, qrcode.Highest, 256)
	file, _ := os.Create("qr.png")
	defer file.Close()
	file.Write(qr_code)
}