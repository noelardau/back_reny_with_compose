import { useState } from 'react';
import { Checkbox, Text, UnstyledButton } from '@mantine/core';
import classes from '../styles/CheckboxCard.module.css';

export function CheckboxResa({eventStat, validateResa}) {
  const [value, onChange] = useState(eventStat != "en_attente");

  return (
    <UnstyledButton onClick={() =>{ onChange(!value); }} className={classes.button}>
      <Checkbox
        checked={value}
        onChange={() => {}}
        tabIndex={-1}
        size="md"
        mr="xl"
        styles={{ input: { cursor: 'pointer' } }}
        aria-hidden
        // c={"green"}
        // color='green'
      />

      <div>
         {value ?
         
        <Text fw={500} mb={7} color='green' lh={1}>Validée</Text>
          :          
        <Text fw={500} mb={7} color='red' lh={1}> En attente
        </Text>        
        
         }
       
      </div>
    </UnstyledButton>
  );
}