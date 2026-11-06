import { Box, Button, Dropdown, LabeledList, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Data = {
  selected_boss: string;
  bosses: string[];
};

export const MegafaunaAltar = () => {
  const { act, data } = useBackend<Data>();
  const { selected_boss, bosses = [] } = data;

  return (
    <Window width={440} height={360} title="Megafauna Summoning Altar">
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section title="Summoning Ritual">
              <Box mb={2}>
                Select the megafauna you wish to challenge. The selected boss
                will appear near the altar when you make the sacrifice.
              </Box>
              <LabeledList>
                <LabeledList.Item label="Megafauna">
                  <Dropdown
                    width="230px"
                    options={bosses.map((boss) => ({
                      displayText: boss,
                      value: boss,
                    }))}
                    selected={selected_boss}
                    onSelected={(boss) => act('select_boss', { boss })}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section title="Begin the Encounter">
              <Box color="bad" mb={2}>
                Warning: the summoned creature is hostile. Clear an arena
                around the altar before starting the ritual.
              </Box>
              <Button
                fluid
                bold
                icon="skull"
                color="red"
                fontSize="18px"
                textAlign="center"
                onClick={() => act('sacrifice')}
              >
                SACRIFICE
              </Button>
              <Box mt={2} color="label">
                The altar is reusable. Summoning does not consume more materials.
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
