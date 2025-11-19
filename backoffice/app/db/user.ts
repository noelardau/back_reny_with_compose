export const user = {
    isConnected: false,
}

export const deconectUser = () => {
    user.isConnected = false;
}

export const conectUser = (username:string, mdp:string) => {
   if(username === "admin" && mdp === "admin"){
    user.isConnected = true;
    return true
   }

   return false

}