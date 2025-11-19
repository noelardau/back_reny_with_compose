
import {useQuery} from '@tanstack/react-query'


export const useQueryGet = (queryKey:string[], url:string) => {  
       
       
       const {error,data,isPending} = useQuery({ queryKey, queryFn:  async () => {
     const response = await fetch(
       url
     )
     return await response.json()}
    
    })

    return {error,data,isPending};
 
}